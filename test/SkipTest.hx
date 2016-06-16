import haxe.unit.async.PromiseTest;
import haxe.unit.async.PromiseTestRunner;

import promhx.Promise;
import promhx.deferred.DeferredPromise;

class SkipTest extends PromiseTest
{
	public function new() {}

	public function testSkip() :Promise<Bool>
	{
		return Promise.promise(true)
			.pipe(function (_) {
				var runner = new PromiseTestRunner();
				runner.add(new Skip());
				return runner.run(false)
					.then(function(_) {
						return true;
					});
		});
	}
}