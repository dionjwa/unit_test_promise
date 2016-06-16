import haxe.unit.async.PromiseTestRunner;

class Tests
{
	public static function main():Void
	{
		new PromiseTestRunner()
			.add(new Test1())
			.add(new Test2())
			.add(new SkipTest())
			.run(false)
			.then(function(success) {
				trace("Finished!");
#if nodejs
				js.Node.process.exit(success ? 0 : 1);
#else
				Sys.exit(success ? 0 : 1);
#end
			});
	}
}