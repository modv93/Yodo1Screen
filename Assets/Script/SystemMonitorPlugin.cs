using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class SystemMonitorPlugin : MonoBehaviour
{
    [DllImport("__Internal")]
    private static extern void _startTracking();

    [DllImport("__Internal")]
    private static extern string _stopTracking();

    public void StartTracking()
    {
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            _startTracking();
        }
    }

    public void StopTracking()
    {
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            string result = _stopTracking();
            Debug.Log(result);
        }
    }
}
