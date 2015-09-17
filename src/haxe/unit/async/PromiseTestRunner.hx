package haxe.unit.async;

#if nodejs
import js.Node;
#end

import promhx.Deferred;
import promhx.Promise;

using Lambda;
using StringTools;

typedef TestResult = {
	var run :Int;
	var passed :Int;
}

class PromiseTestRunner
{
	public var onFinish :Void->Void;

	public function new() :Void {}

	public function setTestTimeout(milliseconds :Int)
	{
		_perTestTimeout = milliseconds;
		return this;
	}

	public function add(testObject :PromiseTest) :PromiseTestRunner
	{
		_tests.push(testObject);
		return this;
	}

	public function run()
	{
		var success = true;
		var doTest = null;
		doTest = function() {
			if (_tests.length == 0) {
				try {
					if (onFinish != null) {
						onFinish();
					}
				} catch (err :Dynamic) {
					trace(err);
				}
#if nodejs
				Node.process.exit(success ? 0 : 1);
#else
				Sys.exit(success ? 0 : 1);
#end
			} else {
				var testObj = _tests.shift();
				if (testObj == null) {
					doTest();
				} else {
					var promise = runTestsOn(testObj)
						.then(function(result :TestResult) {
							if (result.run < result.passed) {
								success = false;
							}
							doTest();
						});
					var millisecondsDelay = Type.getInstanceFields(Type.getClass(testObj)).filter(function(s) return s.startsWith("test")).length * _perTestTimeout;
					haxe.Timer.delay(function() {
						if (!promise.isResolved()) {
							promise.reject('Timeout');
						}
					}, millisecondsDelay);
				}
			}
		}
		doTest();
		return this;
	}

	function runTestsOn(testObj :PromiseTest) :Promise<TestResult>
	{
		var className = Type.getClassName(Type.getClass(testObj));
		var deferred = new Deferred();
		var promise = deferred.promise();

		var run = 0;
		var passed = 0;

		var nextTest = null;
		nextTest = function(testMethodNames :Array<String>) {
			if (testMethodNames.length == 0) {
				trace("Passed " + passed + " / " + run + " " + className);
				deferred.resolve({'run':run, 'passed' :passed});
			} else {
				var fieldName = testMethodNames.shift();
				run++;
				var setupPromise :Null<Promise<Bool>> = testObj.setup();
				setupPromise = setupPromise == null ? Promise.promise(true) : setupPromise;
				setupPromise
					.pipe(function(isSetup :Bool) {
						var result :Promise<Bool> = Reflect.callMethod(testObj, Reflect.field(testObj, fieldName), []);
						return result != null ? result : Promise.promise(true);
					})
					.pipe(function(didPass :Bool) {
						if (didPass) {
							passed++;
							trace(".....Success....." + fieldName);
						} else {
							trace(".....FAILED......" + fieldName);
						}
						var tearDown :Null<Promise<Bool>> = testObj.tearDown();
						return tearDown == null ? Promise.promise(true) : tearDown;
					})
					.then(function(didTearDown :Bool) {
						nextTest(testMethodNames);
					})
					.errorThen(function(err :Dynamic) {
						trace(".....FAILED......" + fieldName);
						trace(err);
						nextTest(testMethodNames);
					});
			}
		}

		nextTest(Type.getInstanceFields(Type.getClass(testObj)).filter(function(s) return s.startsWith("test")));

		return promise;
	}

	var _tests :Array<PromiseTest> = [];
	var _perTestTimeout :Int = 100;
}