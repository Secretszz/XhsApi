﻿// *******************************************
// Company Name:	深圳市晴天互娱科技有限公司
//
// File Name:		AndroidBridgeImpl.cs
//
// Author Name:		Bridge
//
// Create Time:		2024/02/03 16:16:05
// *******************************************

#if UNITY_ANDROID
namespace Bridge.XhsSDK
{
	using Common;
	using UnityEngine;

	/// <summary>
	/// 
	/// </summary>
	internal class AndroidBridgeImpl : IBridge
	{
		private const string UnityPlayerClassName = "com.unity3d.player.UnityPlayer";
		private const string ManagerClassName = "com.bridge.xhsapi.XhsApiUnityBridge";

		private static AndroidJavaObject api;
		private static AndroidJavaObject currentActivity;

		void IBridge.InitSDK(IBridgeListener listener)
		{
			AndroidJavaClass unityPlayer = new AndroidJavaClass(UnityPlayerClassName);
			currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
			AndroidJavaClass jc = new AndroidJavaClass(ManagerClassName);
			api = jc.CallStatic<AndroidJavaObject>("getInstance");
			api.Call("registerApp", currentActivity, new BridgeCallback(listener));
		}

		/// <summary>
		/// 发起图文分享
		/// </summary>
		/// <param name="title">标题</param>
		/// <param name="content">文本内容</param>
		/// <param name="imagePaths">分享的图片列表</param>
		/// <param name="listener">分享回调</param>
		/// <returns>本次分享的唯一标识，每次分享都会改变</returns>
		string IBridge.ShareImage(string title, string content, string[] imagePaths, IBridgeListener listener)
		{
			return api.Call<string>("shareImage", currentActivity, title, content, imagePaths, new BridgeCallback(listener));
		}

		/// <summary>
		/// 发起视频分享
		/// </summary>
		/// <param name="title">标题</param>
		/// <param name="content">文本内容</param>
		/// <param name="videoPaths">分享视频</param>
		/// <param name="imagePath">分享封面图片</param>
		/// <param name="listener">分享回调</param>
		/// <returns>本次分享的唯一标识，每次分享都会改变</returns>
		string IBridge.ShareVideo(string title, string content, string videoPaths, string imagePath, IBridgeListener listener)
		{
			return api.Call<string>("shareVideo", currentActivity, title, content, videoPaths, imagePath, new BridgeCallback(listener));
		}

		/// <summary>
		/// 在小红书打开活动页
		/// </summary>
		/// <param name="url">网页链接，仅支持 http 和 https 链接</param>
		void IBridge.OpenUrlInXhs(string url)
		{
			api.Call("openUrlInXhs", currentActivity, url);
		}

		/// <summary>
		/// 小红书是否已经安装
		/// </summary>
		/// <returns>是否已经安装</returns>
		bool IBridge.IsInstalled()
		{
			return api.Call<bool>("isXhsInstalled", currentActivity);
		}
	}
}
#endif