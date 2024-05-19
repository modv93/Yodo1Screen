using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using UnityEngine.UI;
using TMPro;

public class SystemMonitorPlugin : MonoBehaviour
{
    [SerializeField] private Button startBtn;
    [SerializeField] private Button stopBtn;
    [SerializeField] private TextMeshProUGUI output;

    [DllImport("__Internal")]
    private static extern void _startTracking();

    [DllImport("__Internal")]
    private static extern string _stopTracking();

    public void Awake()
    {
        startBtn.onClick.AddListener(StartTracking);
        stopBtn.onClick.AddListener(StopTracking);
    }

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
            output.text = result;
        }
    }
}
