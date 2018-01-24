using Uno;
using Uno.Diagnostics;
using Uno.Graphics;

using OpenGL;

namespace Fuse.Internal
{
	extern(OpenGL) class GLErrorException : Exception
	{
		public readonly GLError ErrorCode;

		public GLErrorException(GLError glError)
		{
			ErrorCode = glError;
		}

		public override string ToString()
		{
			return base.ToString() + "\nOpenGL error code: " + ErrorCode;
		}
	}

	extern(OpenGL) static class GLHelpers
	{
		public static void CheckError()
		{
			var err = GL.GetError();
			if (err != GLError.NoError)
				throw new GLErrorException(err);
		}

		public static GLShaderHandle CompileShader(GLShaderType type, string source)
		{
			var handle = GL.CreateShader(type);
			GL.ShaderSource(handle, source);
			GL.CompileShader(handle);

			if (GL.GetShaderParameter(handle, GLShaderParameter.CompileStatus) != 1)
			{
				var log = GL.GetShaderInfoLog(handle);
				GL.DeleteShader(handle);
				throw new Exception("Error compiling shader (" + type + "):\n\n" + log + "\n\nSource:\n\n" + source);
			}
			else
			{
				var log = GL.GetShaderInfoLog(handle);
				if (log.Length > 0)
					Debug.Log("error compiling shader: " + log);
			}

			CheckError();
			return handle;
		}

		static bool _driverHasGetProgramInfoLogQuirk;
		public static GLProgramHandle LinkProgram(GLShaderHandle vertexShader, GLShaderHandle fragmentShader)
		{
			var handle = GL.CreateProgram();
			GL.AttachShader(handle, vertexShader);
			GL.AttachShader(handle, fragmentShader);
			GL.LinkProgram(handle);

			if (GL.GetProgramParameter(handle, GLProgramParameter.LinkStatus) != 1)
			{
				var log = GL.GetProgramInfoLog(handle);
				GL.DeleteProgram(handle);
				throw new Exception("Error linking shader program:\n\n" + log);
			}
			else
			{
				if (!_driverHasGetProgramInfoLogQuirk)
				{
					CheckError();
					var log = GL.GetProgramInfoLog(handle);

					/* It seems some OpenGL implementations report InvalidOperation for
					 * successfully linked shaders here, but doing so has no support in
					 * the OpenGL ES 2.0 nor OpenGL 4.6 specifications.
					 */
					var err = GL.GetError();
					if (err != GLError.NoError)
					{
						if (err == GLError.InvalidOperation)
							_driverHasGetProgramInfoLogQuirk = true;
						else
							throw new GLErrorException(err);
					}

					if (log.Length > 0)
						Debug.Log("error linking shader: " + log);
				}
			}

			CheckError();
			return handle;
		}

		public static GLProgramHandle CreateProgram(string vertexShaderSource, string fragmentShaderSource)
		{
			var vertexShader = CompileShader(GLShaderType.VertexShader, vertexShaderSource);
			var fragmentShader = CompileShader(GLShaderType.FragmentShader, fragmentShaderSource);
			return LinkProgram(vertexShader, fragmentShader);
		}

		public static void SetupBlending(bool preMultiplied = true)
		{
			GL.Enable(GLEnableCap.Blend);
			if (preMultiplied)
			{
				GL.BlendFuncSeparate(
					GLBlendingFactor.One, GLBlendingFactor.OneMinusSrcAlpha,
					GLBlendingFactor.OneMinusDstAlpha, GLBlendingFactor.One);
			}
			else
			{
				GL.BlendFuncSeparate(
					GLBlendingFactor.SrcAlpha, GLBlendingFactor.OneMinusSrcAlpha,
					GLBlendingFactor.One, GLBlendingFactor.OneMinusSrcAlpha);
			}
		}

		static GLTextureParameterValue TextureFilterToGL(TextureFilter textureFilter)
		{
			switch (textureFilter)
			{
			case TextureFilter.Nearest: return GLTextureParameterValue.Nearest;
			case TextureFilter.Linear: return GLTextureParameterValue.Linear;
			case TextureFilter.NearestMipmapNearest: return GLTextureParameterValue.NearestMipmapNearest;
			case TextureFilter.LinearMipmapNearest: return GLTextureParameterValue.LinearMipmapNearest;
			case TextureFilter.NearestMipmapLinear: return GLTextureParameterValue.NearestMipmapLinear;
			case TextureFilter.LinearMipmapLinear: return GLTextureParameterValue.LinearMipmapLinear;

			default:
				throw new NotSupportedException("Unsupported texture filter: " + textureFilter);
			}
		}

		static GLTextureParameterValue TextureAddressModeToGL(TextureAddressMode textureAddressMode)
		{
			switch (textureAddressMode)
			{
			case TextureAddressMode.Wrap: return GLTextureParameterValue.Repeat;
			case TextureAddressMode.Clamp: return GLTextureParameterValue.ClampToEdge;
			default:
				throw new NotSupportedException("Unsupported texture address-mode: " + textureAddressMode);
			}
		}

		static void SetupSamplerState(SamplerState samplerState)
		{
			GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MinFilter, TextureFilterToGL(samplerState.MinFilter));
			GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MagFilter, TextureFilterToGL(samplerState.MagFilter));
			GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapS, TextureAddressModeToGL(samplerState.AddressU));
			GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapT, TextureAddressModeToGL(samplerState.AddressV));
		}

		public static void SetupTextureSampler(GLTextureUnit textureUnit, GLTextureHandle textureHandle, SamplerState samplerState)
		{
			GL.ActiveTexture(textureUnit);
			GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
			SetupSamplerState(samplerState);
		}

		public static GLBufferHandle CreateRectangleVertexBuffer()
		{
			var verts = new float2[]
			{
				float2(0, 0),
				float2(1, 0),
				float2(1, 1),

				float2(1, 1),
				float2(0, 1),
				float2(0, 0),
			};

			var vb = new Buffer(verts.Length * sizeof(float2));
			for (int i = 0; i < verts.Length; i++)
				vb.Set(i * sizeof(float2), verts[i]);

			var result = GL.CreateBuffer();
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, result);
			GL.BufferData(GLBufferTarget.ArrayBuffer, vb, GLBufferUsage.StaticDraw);
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GLBufferHandle.Zero);
			return result;
		}
	}
}
