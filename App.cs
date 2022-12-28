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
    Pose bust01Pose;
    Model bust01;

    Pose bust02Pose;
    Model bust02;

    Matrix floorTransform = Matrix.TS(new Vec3(0, -1.5f, 0), new Vec3(30, 0.1f, 30));
    Material floorMaterial;

    Vec3 lightDirection;

    public void Init() 
    {
        bust01 = Model.FromFile("marble_bust.glb", Shader.FromFile("pbrShader.hlsl"));
        //bust01 = Model.FromFile("marble_bust.glb", Shader.Default);
        //bust01.Visuals[0].Material.SetTexture("diffuse", Tex.FromFile("Green_Organic_Diffuse.jpg"));
        bust01.Visuals[0].Material.SetTexture("metal", Tex.FromFile("Green_Organic_MR.jpg"));
        bust01.Visuals[0].Material.SetTexture("normal", Tex.FromFile("metal_grid_normal.jpg"));

        bust02 = bust01.Copy();
        bust02.Visuals[0].Material = new Material(Shader.PBR);
        //bust02.Visuals[0].Material.SetTexture("diffuse", Tex.FromFile("Green_Organic_Diffuse.jpg"));
        bust02.Visuals[0].Material.SetTexture("metal", Tex.FromFile("Green_Organic_MR.jpg"));
        //bust02.Visuals[0].Material.SetTexture("normal", Tex.FromFile("Green_Organic_Normal.jpg"));
        bust02.Visuals[0].Material.SetFloat("metallic", 1);

        floorMaterial = new Material(Shader.FromFile("floor.hlsl"));
        floorMaterial.Transparency = Transparency.Blend;

        bust01Pose = new Pose(0, -0.25f, -0.4f, Quat.FromAngles(0, rotate, 0));
        bust02Pose = new Pose(0.4f, -0.25f, -0.4f, Quat.FromAngles(0, rotate, 0));

        Renderer.SkyTex = Tex.FromCubemapEquirectangular("old_depot.hdr", out SphericalHarmonics lighting);
        Renderer.SkyLight = lighting;

        lightDirection = Renderer.SkyLight.DominantLightDirection;
        //Renderer.EnableSky = false;
    }

    public void Step()
    {
        if (SK.System.displayType == Display.Opaque)
            Mesh.Cube.Draw(floorMaterial, floorTransform);

        UI.Handle("Cube", ref bust01Pose, bust01.Bounds);
        bust01.Draw(bust01Pose.ToMatrix());
        bust02.Draw(bust02Pose.ToMatrix());

        bust01.Visuals[0].LocalTransform = Matrix.R(Quat.FromAngles(0, rotate, 0));
        bust02.Visuals[0].LocalTransform = Matrix.R(Quat.FromAngles(0, rotate, 0));

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