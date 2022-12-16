﻿using StereoKit;

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

    public void Init()
    {
        // Create assets used by the app
        bust = Model.FromFile("marble_bust.glb");
        box = Model.FromMesh(Mesh.GenerateCube(Vec3.One * 0.1f), new Material(Shader.FromFile("testShader.hlsl")));

        floorMaterial = new Material(Shader.FromFile("floor.hlsl"));
        floorMaterial.Transparency = Transparency.Blend;

        //testMaterial = new Material(Shader.FromFile("holoshader.hlsl"));

        //bust.Visuals[0].Material.Shader = Shader.FromFile("holoshader.hlsl");
        bust.Visuals[0].Material = new Material(Shader.FromFile("testShader.hlsl"));
        bust.Visuals[0].Material.Transparency = Transparency.Blend;
        //bust.Visuals[0].Material.FaceCull = Cull.Back;

        bustPose = new Pose(0, -0.25f, -0.4f, Quat.FromAngles(0, rotate, 0));
        boxPose = new Pose(0.2f, -0.25f, -0.4f, Quat.FromAngles(0, 0, 0));
    }

    public void Step()
    {
        if (SK.System.displayType == Display.Opaque)
            Mesh.Cube.Draw(floorMaterial, floorTransform);

        //UI.Handle("Cube", ref bustPose, bust.Bounds);
        bust.Draw(bustPose.ToMatrix());
        box.Draw(boxPose.ToMatrix());

        bustPose.orientation = Quat.FromAngles(0, rotate, 0);
        if (rotate == 359)
        {
            rotate = 0;
        }
        else
        {
            //rotate -= 0.5f;
        }
    }
}