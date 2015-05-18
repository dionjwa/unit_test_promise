package haxe.unit.async;

import promhx.Promise;

class PromiseTest
{
	public function assertTrue(expression :Bool, ?info :Dynamic) :Void
	{
		if (!expression) {
			throw info != null ? info : "Failed assertion";
		}
	}

	public function setup() :Promise<Bool>
	{
		return Promise.promise(true);
	}

	public function tearDown() :Promise<Bool>
	{
		return Promise.promise(true);
	}
}