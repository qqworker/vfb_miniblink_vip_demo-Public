#VisualFreeBasic_Form#  Version=5.8.5
Locked=0

[Form]
Name=MainForm
ClassStyle=CS_DBLCLKS,CS_HREDRAW,CS_VREDRAW
ClassName=
WinStyle=WS_THICKFRAME,WS_CAPTION,WS_SYSMENU,WS_MINIMIZEBOX,WS_MAXIMIZEBOX,WS_CLIPSIBLINGS,WS_CLIPCHILDREN,WS_VISIBLE,WS_EX_WINDOWEDGE,WS_EX_CONTROLPARENT,WS_EX_LEFT,WS_EX_LTRREADING,WS_EX_RIGHTSCROLLBAR,WS_POPUP,WS_SIZEBOX
Style=3 - 常规窗口
Icon=
Caption=浏览器测试
StartPosition=1 - 屏幕中心
WindowState=0 - 正常
Enabled=True
Repeat=False
Left=0
Top=0
Width=971
Height=499
TopMost=False
Child=False
MdiChild=False
TitleBar=True
SizeBox=True
SysMenu=True
MaximizeBox=True
MinimizeBox=True
Help=False
Hscroll=False
Vscroll=False
MinWidth=0
MinHeight=0
MaxWidth=0
MaxHeight=0
NoActivate=False
MousePass=False
TransPer=0
TransColor=SYS,25
Shadow=0 - 无阴影
BackColor=SYS,15
MousePointer=0 - 默认
Tag=
Tab=True
ToolTip=
ToolTipBalloon=False
AcceptFiles=False

[Button]
Name=Command1
Index=-1
Caption=Command1
TextAlign=1 - 居中
Ico=
Enabled=True
Visible=True
Default=False
OwnDraw=False
MultiLine=False
Font=微软雅黑,9,0
Left=36
Top=25
Width=82
Height=52
Layout=0 - 不锚定
MousePointer=0 - 默认
Tag=
Tab=True
ToolTip=
ToolTipBalloon=False


[AllCode]
'这是标准的工程模版，你也可做自己的模版。
'写好工程，复制全部文件到VFB软件文件夹里【template】里即可，子文件夹名为 VFB新建工程里显示的名称
'快去打造属于你自己的工程模版吧。



'typedef struct _mbDownloadBind {
'    void* param;
'    mbNetJobDataRecvCallback recvCallback;
'    mbNetJobDataFinishCallback finishCallback;
'    mbPopupDialogSaveNameCallback saveNameCallback;
'} mbDownloadBind;
Type mbDownloadBind
   param As lParam
   recvCallback As Any Ptr
   finishCallback As Any Ptr
   saveNameCallback As Any Ptr
End Type

Type DownInfo 
   FileName As String
   Url As String
   Length As Long
   Down  As Long 
End Type

Dim Shared MainForm_WebView As Integer 
Sub MainForm_Shown(hWndForm As hWnd,UserData As Integer)  '窗口完全显示后。UserData 来自显示窗口最后1个参数。
   mbInit 0
   MainForm_WebView = mbCreateWebWindow(MB_WINDOW_TYPE_CONTROL ,Me.hWnd ,0 ,0 ,Me.ScaleWidth ,Me.ScaleHeight)
   mbShowWindow MainForm_WebView ,True
   
   '直接使用系统自带的下载
   mbOnDownloadInBlinkThread MainForm_WebView, @MainForm_mbDownloadInBlinkThreadCallback, 0
   mbLoadURL MainForm_WebView, "https://yasuo.360.cn" 
End Sub

Sub MainForm_WM_Size(hWndForm As hWnd, fwSizeType As Long, nWidth As Long, nHeight As Long)  '窗口已经改变了大小
   'fwSizeType = SIZE_MAXHIDE     SIZE_MAXIMIZED   SIZE_MAXSHOW    SIZE_MINIMIZED    SIZE_RESTORED  
   ''            其他窗口最大化   窗口已最大化     其他窗口恢复    窗口已最小化      窗口已调整大小
   'nWidth nHeight  是客户区大小，不是全部窗口大小。
   If fwSizeType = SIZE_MINIMIZED Then Return 
   'xxx.Move AfxScaleX(5), AfxScaleY(5), nWidth - AfxScaleX(10), nHeight - AfxScaleY(30)
   If MainForm_WebView Then mbResize MainForm_WebView, nWidth, nHeight 
End Sub

Sub MainForm_WM_Destroy(hWndForm As hWnd)  '即将销毁窗口
   mbUninit
End Sub

'typedef void(MB_CALL_TYPE* mbGetCookieCallback)(mbWebView webView, void* param, MbAsynRequestState state, const utf8* cookie);
Sub MainForm_mbGetCookieCallback(webView As Long ,param As lParam ,state As Long ,url_utf8 As ZString)
   Debug.Print "获取Cookie", url_utf8   
End Sub

'typedef void(MB_CALL_TYPE*mbPopupDialogSaveNameCallback)(void* ptr, const wchar_t* filePath);
'获取文件的路径
Sub MainForm_mbPopupDialogSaveNameCallback(param As lParam ,filePath As Wstring)
   Dim d As DownInfo Ptr = param
   d->FileName = filePath
   Debug.Print "获取文件路径", filePath   
End Sub

'typedef VOID(MB_CALL_TYPE*mbNetJobDataRecvCallback)(VOID* Ptr, mbNetJob job, Const CHAR* Data, Int length);
'这里可以加进度的提示
Sub MainForm_mbNetJobDataRecvCallback cdecl(ByVal param As Any Ptr ,ByVal job As Any Ptr ,ByVal dataIn As Any Ptr ,ByVal length As Integer)
   Dim d As DownInfo Ptr = param
   d->Down += length
   Debug.Print "已下载", d->Down, d->length
End Sub

'typedef void(MB_CALL_TYPE*mbNetJobDataFinishCallback)(void* ptr, mbNetJob job, mbLoadingResult result);
'这里可以加完成的提示，但是这是在浏览器的线程的，警告框可能不会在最前面
Sub MainForm_mbNetJobDataFinishCallback(ByVal param As Any Ptr ,ByVal job As Any Ptr ,ByVal result As Long)
   Dim d As DownInfo Ptr = param
   
   Debug.Print "下载完成", d->Down, d->length
   Delete d
End Sub

'typedef mbDownloadOpt(MB_CALL_TYPE*mbDownloadInBlinkThreadCallback)(
'    mbWebView webView, 
'    void* param, 
'    size_t expectedContentLength,
'    const char* url, 
'    const char* mime, 
'    const char* disposition, 
'    mbNetJob job, 
'    mbNetJobDataBind* dataBind
'    ) ;
Function MainForm_mbDownloadInBlinkThreadCallback(webView As Long, param As lParam ,expectedContentLength As Long ,url As ZString ,mime As ZString ,disposition As ZString, job As Any Ptr, dataBind As Any Ptr) As Long
   Static d As DownInfo
   d.Length = expectedContentLength
   d.Down = 0
   
   Static downloadBind As mbDownloadBind
   downloadBind.param = Varptr(d)
   downloadBind.recvCallback = @MainForm_mbNetJobDataRecvCallback
   downloadBind.finishCallback = @MainForm_mbNetJobDataFinishCallback
   downloadBind.saveNameCallback = @MainForm_mbPopupDialogSaveNameCallback
   
   MainForm_mbDownloadInBlinkThreadCallback = mbPopupDialogAndDownload(webView ,param ,expectedContentLength ,url ,mime ,disposition ,job ,dataBind ,Varptr(downloadBind))
   Function = 1
End Function

Sub MainForm_Command1_BN_Clicked(hWndForm As hWnd, hWndControl As hWnd)  '单击
   mbGetCookie MainForm_WebView, @MainForm_mbGetCookieCallback, 0
End Sub





