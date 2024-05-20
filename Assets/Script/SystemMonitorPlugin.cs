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
    [SerializeField] private TextMeshProUGUI error;
    private bool bStartLock;
    [DllImport("__Internal")]
    private static extern void _startTracking();

    [DllImport("__Internal")]
    private static extern System.IntPtr _stopTracking();

    public void Awake()
    {
        startBtn.onClick.AddListener(StartTracking);
        stopBtn.onClick.AddListener(StopTracking);
        bStartLock = false;
        error.gameObject.SetActive(false);
    }

    public void StartTracking()
    {
        if (error.gameObject.activeSelf) return;
        if(bStartLock)
        {
            StartCoroutine(ShowError());
            return;
        }
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            _startTracking();
            bStartLock = true;
        }
    }

    public void StopTracking()
    {
        if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            System.IntPtr resultPtr = _stopTracking();
            string result = Marshal.PtrToStringUTF8(resultPtr);
            ProcessResult(result);
        }
    }

    private void ProcessResult(string jsonResult)
    {
        var resultDict = JsonUtility.FromJson<UsageResult>(jsonResult);

        Debug.Log($"CPU - Min: {resultDict.cpu.min}, Max: {resultDict.cpu.max}, Avg: {resultDict.cpu.avg}");
        Debug.Log($"GPU - Min: {resultDict.gpu.min}, Max: {resultDict.gpu.max}, Avg: {resultDict.gpu.avg}");
        Debug.Log($"RAM - Min: {resultDict.ram.min}, Max: {resultDict.ram.max}, Avg: {resultDict.ram.avg}");

        output.text = $"CPU - Min: {resultDict.cpu.min}, Max: {resultDict.cpu.max}, Avg: {resultDict.cpu.avg} \n" +
            ($"GPU - Min: {resultDict.gpu.min}, Max: {resultDict.gpu.max}, Avg: {resultDict.gpu.avg} \n ") +
            ($"RAM - Min: {resultDict.ram.min}, Max: {resultDict.ram.max}, Avg: {resultDict.ram.avg} \n ");

    }
    IEnumerator ShowError()
    {
        error.gameObject.SetActive(true);
        yield return new WaitForSeconds(2);
        error.gameObject.SetActive(false);

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
