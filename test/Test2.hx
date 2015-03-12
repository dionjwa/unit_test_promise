import haxe.unit.async.PromiseTest;

import promhx.Promise;

class Test2 extends PromiseTest
{
	public function new()
	{

	}

	public function testThis1() :Promise<Bool>
	{
		return Promise.promise(true);
	}
}