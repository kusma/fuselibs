using Fuse.Common;

using Uno;
using Uno.Graphics;

using OpenGL;

namespace Fuse.Internal
{
	extern(OpenGL) class GLBlitter
	{
		static GLProgramHandle CreateBlitProgram()
		{
			var vertexShaderSource =
				"#ifdef GL_ES\n" +
				"precision highp float;\n" +
				"#endif\n" +
				"attribute vec2 VertexPositionAttribute;\n" +
				"uniform mat4 VertexTransformUniform;\n" +
				"uniform mat3 TextureTransformUniform;\n" +
				"varying vec2 TextureCoordinate;\n" +
				"void main()\n" +
				"{\n" +
				"\tgl_Position = VertexTransformUniform * vec4(VertexPositionAttribute, 0.0, 1.0);\n" +
				"\tTextureCoordinate = (TextureTransformUniform * vec3(VertexPositionAttribute, 1.0)).xy;\n" +
				"}\n";

			var fragmentShaderSource =
				"#ifdef GL_ES\n" +
				"precision mediump float;\n" +
				"#endif\n" +
				"varying vec2 TextureCoordinate;\n" +
				"uniform sampler2D Texture;\n" +
				"uniform vec4 ColorUniform;\n" +
				"void main()\n" +
				"{\n" +
				"\tgl_FragColor = texture2D(Texture, TextureCoordinate) * ColorUniform;\n" +
				"}\n";

			return GLHelpers.CreateProgram(vertexShaderSource, fragmentShaderSource);
		}

		GLProgramHandle _blitProgramHandle;
		int _blitVertexPositionAttributeLocation;
		GLBufferHandle _rectangleVertexBuffer;

		GLBufferHandle GetRectangleVertexBuffer()
		{
			if (_rectangleVertexBuffer == GLBufferHandle.Zero)
				_rectangleVertexBuffer = GLHelpers.CreateRectangleVertexBuffer();

			return _rectangleVertexBuffer;
		}

		public void Blit(Texture2D texture, SamplerState samplerState,
		                 Rect textureRect, float3x3 textureTransform,
		                 Rect localRect, float4x4 localToClipTransform,
		                 float4 color, Blitter.BlitFlags flags)
		{
			if (_blitProgramHandle == GLProgramHandle.Zero)
			{
				_blitProgramHandle = CreateBlitProgram();
				_blitVertexPositionAttributeLocation = GL.GetAttribLocation(_blitProgramHandle, "VertexPositionAttribute");
			}
			GL.UseProgram(_blitProgramHandle);

			var positionTranslation = Matrix.Translation(localRect.Minimum.X, localRect.Minimum.Y, 0);
			var positionScaling = Matrix.Scaling(localRect.Size.X, localRect.Size.Y, 1);
			var positionMatrix = Matrix.Mul(Matrix.Mul(positionScaling, positionTranslation), localToClipTransform);

			var textureTranslation = float3x3.Identity;
			textureTranslation.M31 = textureRect.Minimum.X;
			textureTranslation.M32 = textureRect.Minimum.Y;

			var textureScaling = float3x3.Identity;
			textureScaling.M11 = textureRect.Size.X;
			textureScaling.M22 = textureRect.Size.Y;
			var textureMatrix = Matrix.Mul(Matrix.Mul(textureScaling, textureTranslation), textureTransform);

			bool preMultiplied = !flags.HasFlag(Blitter.BlitFlags.NonPreMultiplied);
			if (preMultiplied)
				color = float4(color.XYZ * color.W, color.W);

			var vertexTransformUniformLocation = GL.GetUniformLocation(_blitProgramHandle, "VertexTransformUniform");
			var textureTransformUniformLocation = GL.GetUniformLocation(_blitProgramHandle, "TextureTransformUniform");
			var textureUniformLocation = GL.GetUniformLocation(_blitProgramHandle, "Texture");
			var colorUniformLocation = GL.GetUniformLocation(_blitProgramHandle, "ColorUniform");

			GL.UniformMatrix4(vertexTransformUniformLocation, false, positionMatrix);
			GL.UniformMatrix3(textureTransformUniformLocation, false, textureMatrix);
			GL.Uniform1(textureUniformLocation, 0);
			GL.Uniform4(colorUniformLocation, color);

			GLHelpers.SetupBlending(preMultiplied);
			GLHelpers.SetupTextureSampler(GLTextureUnit.Texture0, texture.GLTextureHandle, samplerState);

			// misc render-state
			GL.Disable(GLEnableCap.CullFace);
			GL.Disable(GLEnableCap.DepthTest);
			GL.DepthMask(true);
			GL.ColorMask(true, true, true, true);

			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GetRectangleVertexBuffer());
			GL.VertexAttribPointer(_blitVertexPositionAttributeLocation, 2, GLDataType.Float, false, sizeof(float2), 0);
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GLBufferHandle.Zero);
			GL.EnableVertexAttribArray(_blitVertexPositionAttributeLocation);

			GL.DrawArrays(GLPrimitiveType.Triangles, 0, 6);

			GL.DisableVertexAttribArray(_blitVertexPositionAttributeLocation);
			GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);

			GL.UseProgram(GLProgramHandle.Zero);
		}

		static GLProgramHandle CreateFillProgram()
		{
			var vertexShaderSource =
				"#ifdef GL_ES\n" +
				"precision highp float;\n" +
				"#endif\n" +
				"attribute vec2 VertexPositionAttribute;\n" +
				"uniform mat4 VertexTransformUniform;\n" +
				"void main()\n" +
				"{\n" +
				"\tgl_Position = VertexTransformUniform * vec4(VertexPositionAttribute, 0.0, 1.0);\n" +
				"}\n";

			var fragmentShaderSource =
				"#ifdef GL_ES\n" +
				"precision mediump float;\n" +
				"#endif\n" +
				"uniform vec4 ColorUniform;\n" +
				"void main()\n" +
				"{\n" +
				"\tgl_FragColor = ColorUniform;\n" +
				"}\n";

			return GLHelpers.CreateProgram(vertexShaderSource, fragmentShaderSource);
		}

		GLProgramHandle _fillProgramHandle;
		int _fillVertexPositionAttributeLocation;

		public void Fill(Rect localRect, float4x4 localToClipTransform,
		                 float4 color)
		{
			if (_fillProgramHandle == GLProgramHandle.Zero)
			{
				_fillProgramHandle = CreateFillProgram();
				_fillVertexPositionAttributeLocation = GL.GetAttribLocation(_fillProgramHandle, "VertexPositionAttribute");
			}
			GL.UseProgram(_fillProgramHandle);

			var positionTranslation = Matrix.Translation(localRect.Minimum.X, localRect.Minimum.Y, 0);
			var positionScaling = Matrix.Scaling(localRect.Size.X, localRect.Size.Y, 1);
			var positionMatrix = Matrix.Mul(Matrix.Mul(positionScaling, positionTranslation), localToClipTransform);

			color = float4(color.XYZ * color.W, color.W);

			var vertexTransformUniformLocation = GL.GetUniformLocation(_fillProgramHandle, "VertexTransformUniform");
			var colorUniformLocation = GL.GetUniformLocation(_fillProgramHandle, "ColorUniform");

			GL.UniformMatrix4(vertexTransformUniformLocation, false, positionMatrix);
			GL.Uniform4(colorUniformLocation, color);

			GLHelpers.SetupBlending();

			// misc render-state
			GL.Disable(GLEnableCap.CullFace);
			GL.Disable(GLEnableCap.DepthTest);
			GL.DepthMask(true);
			GL.ColorMask(true, true, true, true);

			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GetRectangleVertexBuffer());
			GL.VertexAttribPointer(_fillVertexPositionAttributeLocation, 2, GLDataType.Float, false, sizeof(float2), 0);
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GLBufferHandle.Zero);
			GL.EnableVertexAttribArray(_fillVertexPositionAttributeLocation);

			GL.DrawArrays(GLPrimitiveType.Triangles, 0, 6);

			GL.DisableVertexAttribArray(_fillVertexPositionAttributeLocation);

			GL.UseProgram(GLProgramHandle.Zero);
		}
	}
}
