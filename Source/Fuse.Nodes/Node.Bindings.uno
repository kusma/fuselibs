using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	/*
		Optimized implementation of IList<Binding> that creates no extra objects unless needed
	*/
	public partial class Node
	{
		[UXContent]
		/** The list of bindings belonging to this node. */
		public IList<Binding> Bindings { get { return this; } } // we can't return _bindings here, because it doesn't root/unroot

		MiniList<Binding> _bindings;

		void Root(Binding b) 
		{ 
			if (IsRootingStarted) b.Root(this);
		}

		void Unroot(Binding b) 
		{ 
			if (IsRootingStarted) b.Unroot();
		}

		void RootBindings()
		{
			for (int i = 0; i < _bindings.Count; i++)
				_bindings[i].Root(this);
		}

		void UnrootBindings()
		{
			for (int i = 0; i < _bindings.Count; i++)
				_bindings[i].Unroot();
		}

		void ICollection<Binding>.Clear()
		{
			if (IsRootingStarted)
				UnrootBindings();
			_bindings.Clear();
		}

		public void Add(Binding item)
		{
			_bindings.Add(item);
			Root(item);
		}

		public bool Remove(Binding item)
		{
			var ret = _bindings.Remove(item);
			Unroot(item);
			return ret;
		}

		bool ICollection<Binding>.Contains(Binding item) { return _bindings.Contains(item); }
		int ICollection<Binding>.Count { get { return _bindings.Count; } }

		public void Insert(int index, Binding item)
		{
			_bindings.Insert(index, item);
			Root(item);
		}

		void IList<Binding>.RemoveAt(int index)
		{
			Unroot(_bindings[index]);
			_bindings.RemoveAt(index);
		}

		Binding IList<Binding>.this[int index] { get { return _bindings[index]; } }
		IEnumerator<Binding> IEnumerable<Binding>.GetEnumerator() { return _bindings.GetEnumerator(); }
	}
}
