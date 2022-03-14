unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.StdCtrls, FMX.Controls.Presentation, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Rtti,
  FMX.ScrollBox, FMX.Grid, FMX.Memo, FMX.TabControl, FMX.Memo.Types,
{$IFDEF ANDROID}
  FMX.Helpers.Android, Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText,
{$ENDIF}
  Json, FMX.Objects;

const
  NOT_BUSY = 0;
  BUSY = 1;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    ShadowEffect4: TShadowEffect;
    NetHTTPRequest1: TNetHTTPRequest;
    Button1: TButton;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Memo1: TMemo;
    NetHTTPClient1: TNetHTTPClient;
    Image1: TImage;
    TabItem3: TTabItem;
    Image2: TImage;
    Button2: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    path: string;
    ColorizedImagePath: string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  System.Threading, System.Net.Mime, System.IOUtils;

procedure TForm1.Button1Click(Sender: TObject);
begin
  TTask.Run(
    procedure
    var
      LMultipartFormData: TMultipartFormData;
      LMS: TMemoryStream;
      header: TNameValuePair;
      Json: TJSONObject;
    begin

      LMultipartFormData := TMultipartFormData.Create;

      header := TNameValuePair.Create('api-key',
        '7c224048-9e97-4c4');

    {$IFDEF ANDROID}
      path := TPath.Combine(TPath.GetSharedPicturesPath, 'Einstein.jpeg');
      LMultipartFormData.AddFile('image', path, 'image/*');
      Image1.Bitmap.LoadFromFile(path);
    {$ENDIF}

    {$IFDEF MSWINDOWS}
      path := 'c:\Einstein.jpeg';
      LMultipartFormData.AddFile('image', path, 'application/octet-stream');
      Image1.Bitmap.LoadFromFile(path);
    {$ENDIF}

       LMS := TMemoryStream.Create;

       NetHTTPRequest1.Post('https://api.deepai.org/api/colorizer',
       LMultipartFormData, LMS, [header]);

      TThread.Synchronize(nil,
        procedure
        begin
          Memo1.Lines.LoadFromStream(LMS);
          TabControl1.GotoVisibleTab(1)
        end);

      Json := TJSONObject.ParseJSONValue(Memo1.Text) as TJSONObject;

      TThread.Synchronize(nil,
        procedure
        begin
          ColorizedImagePath := Json.GetValue('output_url').Value;
        end);

      LMS.Free;
      LMultipartFormData.Free;
    end);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Label2.Text := ColorizedImagePath;
  if NetHTTPClient1.Tag = NOT_BUSY then
  begin
    NetHTTPClient1.Tag := BUSY;
    TTask.Run(
      procedure
      var
        LResponse: TMemoryStream;
      begin
        LResponse := TMemoryStream.Create;
        try
          NetHTTPClient1.Get(ColorizedImagePath, LResponse);
          TThread.Synchronize(nil,
            procedure
            begin
              Image2.Bitmap.LoadFromStream(LResponse);
            end);
        finally
          LResponse.Free;
          NetHTTPClient1.Tag := NOT_BUSY;
          TabControl1.GotoVisibleTab(2)
        end;
      end);
  end;
end;

end.
