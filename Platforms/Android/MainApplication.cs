using Android.App;
using Android.Runtime;
using System;

namespace StereoKit_Shaders;

[Application]
public class MainApplication : Application
{
	public MainApplication(IntPtr handle, JniHandleOwnership ownership)
		: base(handle, ownership)
	{
	}
}
