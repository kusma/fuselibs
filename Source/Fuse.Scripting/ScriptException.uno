
namespace Fuse.Scripting
{
	public class ScriptException: Uno.Exception
	{
		public string Name { get; private set;}
		public string FileName { get; private set;}
		public int LineNumber { get; private set;}
		public string SourceLine { get; private set;}
		public string JSStackTrace { get; private set;}

		public ScriptException(
			string name,
			string message,
			string fileName,
			int lineNumber,
			string sourceLine,
			string stackTrace) : base(message)
		{
			Name = name;
			FileName = fileName;
			LineNumber = lineNumber;
			SourceLine = sourceLine;
			JSStackTrace = stackTrace;
		}

		public override string ToString()
		{
			var stringBuilder = new Uno.Text.StringBuilder();
			if (!string.IsNullOrEmpty(Name))
			{
				stringBuilder.Append("Name: ");
				stringBuilder.AppendLine(Name);
			}
			if (!string.IsNullOrEmpty(FileName))
			{
				stringBuilder.Append("File name: ");
				stringBuilder.AppendLine(FileName);
			}
			if (LineNumber >= 0)
			{
				stringBuilder.Append("Line number: ");
				stringBuilder.AppendLine(LineNumber.ToString());
			}
			if (!string.IsNullOrEmpty(SourceLine))
			{
				stringBuilder.Append("Source line: ");
				stringBuilder.AppendLine(SourceLine);
			}
			if (!string.IsNullOrEmpty(JSStackTrace))
			{
				stringBuilder.Append("JS stack trace: ");
				stringBuilder.AppendLine(JSStackTrace);
			}
			return base.ToString() + "\n" + stringBuilder.ToString();
		}
	}
}
