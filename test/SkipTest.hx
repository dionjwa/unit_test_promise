import haxe.unit.async.PromiseTest;
import haxe.unit.async.PromiseTestRunner;

import promhx.Promise;
import promhx.Deferred;

class SkipTest extends PromiseTest
{
	public function new() {}

	public function testSkip() :Promise<Bool>
	{
		return Promise.promise(true)
		.then(function (_) {
			var runner = new PromiseTestRunner();
			runner.add(new Skip());
			runner.run();
			assertEquals(runner.getTotalTestsRun(), 0);
			return true;
		});
	}
}