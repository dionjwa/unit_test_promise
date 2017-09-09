package haxe.unit.async;

#if nodejs
import js.Node;
#end

import haxe.rtti.Meta;

import promhx.Deferred;
import promhx.Promise;
import promhx.deferred.DeferredPromise;

import t9.util.ColorTraces.*;

using Lambda;
using StringTools;

typedef TestResult = {
	var run :Int;
	var passed :Int;
}

typedef Test = {
	var name :String;
	@:optional var error :String;
	var passed :Bool;
}

typedef CompleteTestResult = {
	var tests :Array<Test>;
	var run :Int;
	var passed :Int;
	var success :Bool;
}

class PromiseTestRunner
{
	static var RED="\033[0;31m";
	static var GREEN="\033[0;32m";
	static var NC="\033[0m";//No Color
	var _totalTestsRun :Int;
	var _totalTestsPassed :Int;
	var _finalTestResult :CompleteTestResult;
	var _disableTrace :Bool = false;

	public function new() :Void
	{
		_totalTestsRun = 0;
		_totalTestsPassed = 0;
	}

	public function setDefaultTimeout(milliseconds :Int)
	{
		_defaultTestTimeout = milliseconds;
		return this;
	}

	public function add(testObject :PromiseTest) :PromiseTestRunner
	{
		_tests.push(testObject);
		return this;
	}

	public function run(?exitOnFinish :Bool = true, ?disableTrace :Bool = false) :Promise<CompleteTestResult>
	{
		filterOnly();
		_disableTrace = disableTrace;
		var promise = new DeferredPromise();
		var success = true;
		var doTest = null;
		_totalTestsRun = 0;
		_totalTestsPassed = 0;
		_finalTestResult = {tests:[], run:0, passed:0, success:true};
		doTest = function() {
			if (_tests.length == 0) {
				if (_totalTestsPassed < _totalTestsRun) {
					traceRed('TOTAL TESTS PASSED ${_totalTestsPassed} / ${_totalTestsRun}');
				} else {
					traceGreen('TOTAL TESTS PASSED ${_totalTestsPassed} / ${_totalTestsRun}');
				}
				try {
					haxe.Timer.delay(function () {
						if (promise != null) {
							promise.resolve(_finalTestResult);
							promise = null;
						}

						if (exitOnFinish) {
#if nodejs
							Node.process.exit(success ? 0 : 1);
#else
							Sys.exit(success ? 0 : 1);
#end
						}
					}, 0);
				} catch (err :Dynamic) {
					try {
						trace(err);
						if (promise != null) {
							promise.boundPromise.reject(err);
							promise = null;
						}
					} catch (e :Dynamic) {
						trace(err);
					}
				}
			} else {
				var testObj = _tests.shift();
				if (testObj == null) {
					doTest();
				} else {
					runTestsOn(testObj)
						.then(function(result :CompleteTestResult) {
							_finalTestResult = merge(_finalTestResult, result);
							_totalTestsRun += result.run;
							_totalTestsPassed += result.passed;
							if (result.run > result.passed) {
								success = false;
							}
							doTest();
						})
						.catchError(function(err) {
							trace(err);
							doTest();
						});
				}
			}
		}
		doTest();
		return promise.boundPromise;
	}

	function runTestsOn(testObj :PromiseTest) :Promise<CompleteTestResult>
	{
		var alltestsResult :CompleteTestResult = {tests:[], run:0, passed:0, success:true};
		var className = Type.getClassName(Type.getClass(testObj));
		var promise = new DeferredPromise();

		var nextTest = null;
		nextTest = function(testMethodNames :Array<String>) {
			if (testMethodNames.length == 0) {
				alltestsResult.run = alltestsResult.tests.length;
				alltestsResult.passed = alltestsResult.tests.count(function(t) return t.passed);
				alltestsResult.success = alltestsResult.run == alltestsResult.passed;
				if (!alltestsResult.success) {
					traceRed('Passed ${alltestsResult.passed} / ${alltestsResult.run} ${className}');
				} else {
					traceGreen('Passed ${alltestsResult.passed} / ${alltestsResult.run} ${className}');
				}
				if (promise != null) {
					promise.resolve(alltestsResult);
					promise = null;
				}
			} else {
				var fieldName = testMethodNames.shift();

				var timeout = _defaultTestTimeout;
				var fieldMetaData = Reflect.field(Meta.getFields(Type.getClass(testObj)), fieldName);
				if (fieldMetaData != null && Reflect.hasField(fieldMetaData, 'timeout')) {
					timeout = Reflect.field(fieldMetaData, 'timeout');
				}
				var testResult = {name:fieldName, error:null, passed:false};

				// alltestsResult.run++;
				alltestsResult.tests.push(testResult);
				var setupPromise :Null<Promise<Bool>> = testObj.setup();
				setupPromise = setupPromise == null ? Promise.promise(true) : setupPromise;
				setupPromise
					.pipe(function(isSetup :Bool) {
						var p = new DeferredPromise();
						var result :Promise<Bool> = Reflect.callMethod(testObj, Reflect.field(testObj, fieldName), []);
						if (result == null) {
							result = Promise.promise(true);
						}
						var timer = haxe.Timer.delay(function() {
							if (p != null) {
								traceRed('.....${fieldName} timed out.....');
								p.boundPromise.reject('PromiseTestRunner runTestsOn ${className}.${fieldName} Timeout');
								p = null;
							}
						}, timeout);
						result
							.then(function(out) {
								timer.stop();
								if (p != null) {
									p.resolve(out);
									p = null;
								}
							})
							.catchError(function(err) {
								timer.stop();
								if (p != null) {
									p.boundPromise.reject(err);
									p = null;
								} else {
									trace(err);
								}
							});
						return p.boundPromise;
					})
					.pipe(function(didPass :Bool) {
						if (didPass) {
							testResult.passed = true;
							// alltestsResult.passed++;
							traceGreen('.....Success.....${fieldName}');
						} else {
							traceRed('.....FAILED......${fieldName}');
						}
						var tearDown :Null<Promise<Bool>> = testObj.tearDown();
						return tearDown == null ? Promise.promise(true) : tearDown;
					})
					.then(function(didTearDown :Bool) {
						nextTest(testMethodNames);
					})
					.errorThen(function(err :Dynamic) {
						var errorString :String = '';
						if (err != null) {
							try {
								if (Reflect.hasField(err, 'stack')) {
									errorString = err.stack;
								} else {
									errorString = err + '';
								}
							} catch (_:Dynamic) {
								trace(err);
							}
						}
						testResult.error = errorString;
						traceRed('.....FAILED......${fieldName}\n${errorString}');
						nextTest(testMethodNames);
					});
			}
		}

		js.Node.setTimeout(function() {
			nextTest(getActiveTests(testObj));
		}, 0);

		return promise.boundPromise;
	}

	private static function getActiveTests(testObj :PromiseTest) :Array<String>
	{
		var testClass = Type.getClass(testObj);
		var only :String = null;
		return Type.getInstanceFields(testClass).filter(function (fieldName) {
			if (fieldName.startsWith("test")) {
				var fieldMetaData = Reflect.field(Meta.getFields(testClass), fieldName);
				if (fieldMetaData != null && Reflect.hasField(fieldMetaData, 'only')) {
					only = fieldName;
				}
				if (fieldMetaData == null || !Reflect.hasField(fieldMetaData, 'skip')) {
					return true;
				}
			}
			return false;
		}).filter(function(fieldName) {
			if (only == null) {
				return true;
			} else {
				return fieldName == only;
			}
		});
	}

	public function getTotalTestsRun() :Int
	{
		return _totalTestsRun;
	}

	public function getTotalTestsPassed() :Int
	{
		return _totalTestsPassed;
	}

	function filterOnly()
	{
		var only = _tests.find(function(testObj) {
			var testClass = Type.getClass(testObj);
			return Type.getInstanceFields(testClass).exists(function (fieldName) {
				if (fieldName.startsWith("test")) {
					var fieldMetaData = Reflect.field(Meta.getFields(testClass), fieldName);
					if (fieldMetaData != null && Reflect.hasField(fieldMetaData, 'only')) {
						return true;
					}
				}
				return false;
			});
		});
		if (only != null) {
			_tests = [only];
		}
	}

	function traceRed(s :Dynamic)
	{
		if (!_disableTrace) {
			trace('${RED}${s}${NC}');
		}
	}

	function traceGreen(s :Dynamic)
	{
		if (!_disableTrace) {
			trace('${GREEN}${s}${NC}');
		}
	}

	static function merge(a :CompleteTestResult, b :CompleteTestResult) :CompleteTestResult
	{
		var merged :CompleteTestResult = {run:0, passed:0, tests:[], success:true};
		merged.run =  a.run + b.run;
		merged.passed =  a.passed + b.passed;
		merged.tests = a.tests.concat(b.tests);
		merged.success = a.success && b.success;
		return merged;
	}

	var _tests :Array<PromiseTest> = [];
	var _defaultTestTimeout :Int = 60;
}