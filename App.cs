using Microsoft.Maui.Controls.Xaml;
using StereoKit;
using System.Data;

namespace StereoKit_Shaders;

public class App
{
    public SKSettings Settings => new SKSettings
    {
        appName = "StereoKit_Shaders",
        assetsFolder = "Assets",
        displayPreference = DisplayMode.MixedReality
    };

    float rotate = 180f;
    Pose bustPose;
    Model bust;

    Pose boxPose;
    Model box;

    Matrix floorTransform = Matrix.TS(new Vec3(0, -1.5f, 0), new Vec3(30, 0.1f, 30));
    Material floorMaterial;

    Vec3 lightDirection;

    public void Init()
    {
        // Create assets used by the app
        bust = Model.FromFile("marble_bust.glb", Shader.FromFile("standardShader.hlsl"));
        //bust.Visuals[0].Material.SetTexture("metal", Tex.FromFile("Random_Nicey_Neon_Green_Organic_MR.jpg"));
        //bust.Visuals[0].Material.SetTexture("diffuse", Tex.FromFile("Random_Nicey_Neon_Green_Organic_Diffuse.jpg"));
        bust.Visuals[0].Material.SetTexture("normal", Tex.FromFile("Random_Nicey_Neon_Green_Organic_Normal.jpg"));

        box = bust.Copy();
        box.Visuals[0].Material = new Material(Shader.Default);
        //Model.FromMesh(Mesh.GenerateCube(Vec3.One * 0.1f), new Material(Shader.FromFile("standardShader.hlsl")));

        floorMaterial = new Material(Shader.FromFile("floor.hlsl"));
        floorMaterial.Transparency = Transparency.Blend;

        //bust.Visuals[0].Material.Transparency = Transparency.Blend;
        //bust.Visuals[0].Material.FaceCull = Cull.Front;

        bustPose = new Pose(0, -0.25f, -0.4f, Quat.FromAngles(0, rotate, 0));
        boxPose = new Pose(0.4f, -0.25f, -0.4f, Quat.FromAngles(0, rotate, 0));

        Renderer.SkyTex = Tex.FromCubemapEquirectangular("old_depot.hdr", out SphericalHarmonics lighting);
        Renderer.SkyLight = lighting;

        lightDirection = Renderer.SkyLight.DominantLightDirection;
        //Renderer.EnableSky = false;
    }

    public void Step()
    {
        if (SK.System.displayType == Display.Opaque)
            Mesh.Cube.Draw(floorMaterial, floorTransform);

        UI.Handle("Cube", ref bustPose, bust.Bounds);
        bust.Draw(bustPose.ToMatrix());
        box.Draw(boxPose.ToMatrix());

        bust.Visuals[0].LocalTransform = Matrix.R(Quat.FromAngles(0, rotate, 0));

        if (rotate == 359)
        {
            rotate = 0;
        }
        else
        {
           //rotate -= 0.5f;
        }

        Lines.Add(new Ray(Vec3.One, lightDirection), 1, Color32.White, 0.01f);
    }
}