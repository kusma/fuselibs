using Uno;
using Uno.Graphics;

using OpenGL;

namespace Fuse.Internal
{
	extern(OpenGL) static class GLHelpers
	{
		public static GLProgramHandle CreateProgram(string vertexShaderSource, string fragmentShaderSource)
		{
			var vertexShader = Uno.Runtime.Implementation.ShaderBackends.OpenGL.GLHelpers.CompileShader(GLShaderType.VertexShader, vertexShaderSource);
			var fragmentShader = Uno.Runtime.Implementation.ShaderBackends.OpenGL.GLHelpers.CompileShader(GLShaderType.FragmentShader, fragmentShaderSource);
			return Uno.Runtime.Implementation.ShaderBackends.OpenGL.GLHelpers.LinkProgram(vertexShader, fragmentShader);
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
