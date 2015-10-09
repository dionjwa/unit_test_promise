import haxe.unit.async.PromiseTest;

import promhx.Promise;
import promhx.Deferred;

class Test1 extends PromiseTest
{
	var _isSetup :Bool = false;

	public function new()
	{

	}

	override public function setup() :Promise<Bool>
	{
		_isSetup = true;
		return Promise.promise(true);
	}

	override public function tearDown() :Promise<Bool>
	{
		_isSetup = false;
		return Promise.promise(true);
	}

	public function testThis1() :Promise<Bool>
	{
		return Promise.promise(true);
	}

	@timeout(150)
	public function testThis2() :Promise<Bool>
	{
		var deferred = new Deferred();
		haxe.Timer.delay(function()  {
			deferred.resolve(_isSetup);
		}, 100);
		return deferred.promise();
	}

	@timeout(100)
	public function testThis3() :Promise<Bool>
	{
		var deferred = new Deferred();
		haxe.Timer.delay(function()  {
			deferred.resolve(_isSetup);
		}, 50);
		return deferred.promise();
	}

	public function testThis4() :Promise<Bool>
	{
		var deferred = new Deferred();
		haxe.Timer.delay(function()  {
			deferred.resolve(_isSetup);
		}, 50);
		return deferred.promise();
	}

	public function testThis5() :Promise<Bool>
	{
		assertTrue(true);
		assertFalse(false);
		assertIsNull(null);
		assertNotNull('foo');
		assertEquals(3, 3);
		assertNotEquals(3, 4);
		return Promise.promise(true);
	}
}