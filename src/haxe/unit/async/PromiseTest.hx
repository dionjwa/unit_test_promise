package haxe.unit.async;

import promhx.Promise;

class PromiseTest
{
	public function setup() :Promise<Bool>
	{
		return Promise.promise(true);
	}

	public function tearDown() :Promise<Bool>
	{
		return Promise.promise(true);
	}
}