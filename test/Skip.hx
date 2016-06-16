import haxe.unit.async.PromiseTest;

import promhx.Promise;

class Skip extends PromiseTest
{
	public function new() {}

	@skip
	public function testNothing() :Promise<Bool>
	{
		trace("you shouldn't see this");
		throw 'you should not see this';
		return Promise.promise(true);
	}
}