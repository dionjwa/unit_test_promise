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
				runner.setSkipExit(true);
				var deferred = new DeferredPromise();
				runner.run().onFinish = function() {
					if (runner.getTotalTestsRun() == 0) {
						deferred.resolve(true);
					} else {
						deferred.boundPromise.reject('runner.getTotalTestsRun()=${runner.getTotalTestsRun()}');
					}
				};
				return deferred.boundPromise;
		});
	}
}