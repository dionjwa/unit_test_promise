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
	public function new() :Void
	{
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
#if nodejs
				Node.process.exit(success ? 0 : 1);
#else
				Sys.exit(success ? 0 : 1);
#end
			} else {
				var testObj = _tests.shift();
				runTestsOn(testObj)
					.then(function(result :TestResult) {
						if (result.run < result.passed) {
							success = false;
						}
						doTest();
					});
			}
		}
		doTest();
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
				trace("Passed " + passed + " / " + run + " " + Type.getClassName(Type.getClass(testObj)));
				deferred.resolve({'run':run, 'passed' :passed});
			} else {
				var fieldName = testMethodNames.shift();
				run++;
				testObj.setup()
					.pipe(function(isSetup :Bool) {
						var result :Promise<Bool> = Reflect.callMethod(testObj, Reflect.field(testObj, fieldName), []);
						return result;
					})
					.pipe(function(didPass :Bool) {
						if (didPass) {
							passed++;
							trace(".....Success....." + fieldName);
						} else {
							trace(".....FAILED......" + fieldName);
						}
						return testObj.tearDown();
					})
					.then(function(didTearDown :Bool) {
						nextTest(testMethodNames);
					})
					.errorThen(function(err :Dynamic) {
						trace("Error cleaning up: " + err);
						nextTest(testMethodNames);
					});
			}
		}

		nextTest(Type.getInstanceFields(Type.getClass(testObj)).filter(function(s) return s.startsWith("test")));

		return promise;
	}

	var _tests :Array<PromiseTest> = [];
}