import haxe.unit.async.PromiseTestRunner;

class Tests
{
	public static function main():Void
	{
		new PromiseTestRunner()
			.add(new Test1())
			.add(new Test2())
			.add(new SkipTest())
			.run().onFinish = function() trace("Finished!");
	}
}