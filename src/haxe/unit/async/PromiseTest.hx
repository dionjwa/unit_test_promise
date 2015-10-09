package haxe.unit.async;

/**
 * And subclasses with methods beginning with 'test'
 * are considered test functions.
 *
 * Test functions can have the following metadata:
 *
 * @timeout(100)	This sets a custom timeout for that test
 */

import promhx.Promise;
import promhx.base.AsyncBase;

class PromiseTest
{
	public function assertTrue(expression :Bool, ?posInfos :haxe.PosInfos) :Void
	{
		if (!expression) {
			throw '${posInfos.className}.${posInfos.methodName}:${posInfos.lineNumber} Failed assertion';
		}
	}

	public function assertFalse(expression :Bool, ?posInfos :haxe.PosInfos) :Void
	{
		assertTrue(!expression, posInfos);
	}

	public function assertEquals(val1 :Dynamic, val2 :Dynamic, ?posInfos :haxe.PosInfos) :Void
	{
		if (val1 != val2) {
			throw '${posInfos.className}.${posInfos.methodName}:${posInfos.lineNumber} Failed assertion: ${val1} != ${val2}';
		}
	}

	public function assertNotEquals(val1 :Dynamic, val2 :Dynamic, ?posInfos :haxe.PosInfos) :Void
	{
		if (val1 == val2) {
			throw '${posInfos.className}.${posInfos.methodName}:${posInfos.lineNumber} Failed assertion: ${val1} == ${val2}';
		}
	}

	public function assertIsNull(val1 :Dynamic, ?posInfos :haxe.PosInfos) :Void
	{
		if (val1 != null) {
			throw '${posInfos.className}.${posInfos.methodName}:${posInfos.lineNumber} Failed assertion: ${val1} != null';
		}
	}

	public function assertNotNull(val1 :Dynamic, ?posInfos :haxe.PosInfos) :Void
	{
		if (val1 == null) {
			throw '${posInfos.className}.${posInfos.methodName}:${posInfos.lineNumber} Failed assertion: ${val1} == null';
		}
	}

	public function setup() :Null<Promise<Bool>>
	{
		return Promise.promise(true);
	}

	public function tearDown() :Null<Promise<Bool>>
	{
		return Promise.promise(true);
	}
}