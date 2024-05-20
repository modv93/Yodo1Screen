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
    private static extern System.IntPtr _stopTracking();

    public void Awake()
    {
        startBtn.onClick.AddListener(StartTracking);
        stopBtn.onClick.AddListener(StopTracking);
        startBtn.interactable = true;
        stopBtn.interactable = false;
    }

    public void StartTracking()
    {
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            startBtn.interactable = false;
            stopBtn.interactable = true;
            _startTracking();
        }
    }

    public void StopTracking()
    {
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            stopBtn.interactable = false;
            startBtn.interactable = true;
            System.IntPtr resultPtr = _stopTracking();
            string result = Marshal.PtrToStringUTF8(resultPtr);
            ProcessResult(result);
        }
    }

    private void ProcessResult(string jsonResult)
    {
        var resultDict = JsonUtility.FromJson<UsageResult>(jsonResult);

        Debug.Log($"CPU - Min: {resultDict.cpu.min}%, Max: {resultDict.cpu.max}%, Avg: {resultDict.cpu.avg}% \n");
        Debug.Log($"GPU - Min: {resultDict.gpu.min}%, Max: {resultDict.gpu.max}%, Avg: {resultDict.gpu.avg}% \n");
        Debug.Log($"RAM - Min: {resultDict.ram.min} MB, Max: {resultDict.ram.max} MB, Avg: {resultDict.ram.avg} MB \n");

        output.text = $"CPU - Min: {resultDict.cpu.min}%, Max: {resultDict.cpu.max}%, Avg: {resultDict.cpu.avg}% \n" +
            ($"GPU - Min: {resultDict.gpu.min * 100}%, Max: {resultDict.gpu.max * 100}%, Avg: {resultDict.gpu.avg * 100}% \n") +
            ($"RAM - Min: {resultDict.ram.min /(1024*1024)} MB, Max: {resultDict.ram.max / (1024 * 1024)} MB, Avg: {resultDict.ram.avg / (1024 * 1024)} MB \n");

    }

    [System.Serializable]
    private class UsageStats
    {
        public double min;
        public double max;
        public double avg;
    }

    [System.Serializable]
    private class UsageResult
    {
        public UsageStats cpu;
        public UsageStats gpu;
        public UsageStats ram;
    }
}
