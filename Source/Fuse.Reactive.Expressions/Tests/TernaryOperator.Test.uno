using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	/**
		TernaryOperator is part of the Uno-level API, this tries to cover the intended high-level functionality.
	*/
	public class TernaryOperatorTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.TernaryOperator.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				
				p.strct.Value = p.strctData1.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "xy*", p.d.ObjectValue );
				
				p.strct.Value = p.strctData2.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "x*z", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				
				p.strct.Value = p.strctData3.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "*yz", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				
				p.strct.Value = p.strctData4.Value;
				root.PumpDeferred();
				Assert.AreEqual( "xyz", p.a.ObjectValue );
				Assert.AreEqual( "xyz", p.b.ObjectValue );
				Assert.AreEqual( "xyz", p.c.ObjectValue );
				Assert.AreEqual( "xyz", p.d.ObjectValue );
			}
		}
	}
	
	[UXFunction("_terJoin")]
	class TerJoin : TernaryOperator
	{
		[UXConstructor]
		public TerJoin([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third)
			: base(first, second, third)
		{}
			
		protected override object Compute(object first, object second, object third)
		{
			return (first == null ? "*" : first.ToString()) +
				(second == null ? "*" : second.ToString()) +
				(third == null ? "*" : third.ToString());
		}
	}
	
	[UXFunction("_terJoin1")]
	class TerJoin1 : TerJoin
	{
		[UXConstructor]
		public TerJoin1([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third)
			: base(first, second, third)
		{}
			
		protected override bool IsFirstOptional { get { return true; } }
	}
	
	[UXFunction("_terJoin2")]
	class TerJoin2 : TerJoin
	{
		[UXConstructor]
		public TerJoin2([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third)
			: base(first, second, third)
		{}
			
		protected override bool IsSecondOptional { get { return true; } }
	}
	
	[UXFunction("_terJoin3")]
	class TerJoin3 : TerJoin
	{
		[UXConstructor]
		public TerJoin3([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third)
			: base(first, second, third)
		{}
			
		protected override bool IsThirdOptional { get { return true; } }
	}
	
}
