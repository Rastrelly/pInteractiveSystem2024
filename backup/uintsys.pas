unit uIntSys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DateUtils;

type

  PImage = ^TImage;

  TControlledBall = class
    public
      x,y,r:real;
      spdx:real;
      mkx:integer;
      xArea:integer;
      yArea:integer;
      function getRInt:integer;
      procedure move(dt:real; tPos:real);
      constructor create(bx:real; by:real; bspdx:real);
  end;

  PControlledBall = ^TControlledBall;


  TRenderThread = class(TThread)
    private
      targetImage:PImage;
      timeLast,timeNow:TDateTime;
      iter:integer;
      tPos:real;
      dtAccum:real;
      fpsDes:Integer;
      dtTresh:real;
      procedure Render;
    public
      run:boolean;
      refBall:PControlledBall;
      renderW, renderH:integer;
      procedure Execute; override;
      constructor Create(createSuspended:boolean;trgImage:PImage);
  end;


  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PaintBox1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  renderer:TRenderThread;
  ourBall:TControlledBall;


implementation

{$R *.lfm}

function TControlledBall.getRInt:integer;
begin
  Result:=Round(r);
end;

procedure TControlledBall.move(dt:real; tPos:real);
begin
  x:=x+spdx*dt*mkx;

  if ((x-r)<0) then x:=r;
  if ((x+r)>xArea) then x:=xArea-r;

  y:=sin(100*tPos*3.14 / 180)*yArea*0.5 + 0.5*yArea;

end;

constructor TControlledBall.create(bx:real; by:real; bspdx:real);
begin
  x:=bx;
  y:=by;
  spdx:=bspdx;
  mkx:=0;
end;

procedure TRenderThread.Render;
var renderBitmap:TBitmap;
    elY, dt:real;
    rbX, rbY, rbR:integer;
begin

  inc(iter);

  timeNow:=Now;
  dt:=MilliSecondsBetween(timeNow,timeLast)/1000;
  dtAccum:=dtAccum+dt;
  tPos:=tPos+dt;

  refBall^.move(dt, tPos);

  rbX:=Round(refBall^.x);
  rbY:=Round(refBall^.y);
  rbR:=refBall^.getRInt;

  timeLast:=timeNow;

  if (dtAccum > dtTresh) then
  begin

  dtAccum:=0;

  renderBitmap:=TBitmap.Create;
  renderBitmap.Width:=renderW;
  renderBitmap.Height:=renderH;

  targetImage^.Picture.Bitmap.Width:=targetImage^.Width;
  targetImage^.Picture.Bitmap.Height:=targetImage^.Height;




  with renderBitmap.Canvas do
  begin
    pen.Color:=clBlack;
    Brush.Color:=clWhite;
    Rectangle(0,0,renderW,renderH);
    Brush.Color:=clRed;
    Ellipse(rbx-rbr,rby-rbr,rbx+rbr,rby+rbr);
  end;

  targetImage^.Canvas.CopyRect(rect(0,0,targetImage^.Width, targetImage^.Height),
                         renderBitmap.Canvas,
                         rect(0,0,renderBitmap.Width,renderBitmap.Height));

  FreeAndNil(renderBitmap);

  Form1.Caption:=floattostr(dt);

  end;
end;

constructor TRenderThread.Create(createSuspended:boolean;trgImage:PImage);
begin
  inherited Create(createSuspended);
  targetImage:=trgImage;
  renderW:=800;
  renderH:=600;
  run:=True;
  timeLast:=Now;
  timeNow:=Now;
  iter:=0;
  tPos:=0;
  dtAccum:=0;
  fpsDes:=60;
  dtTresh:=1/fpsDes;
end;

procedure TRenderThread.Execute;
begin
  while (run) do
  begin
    Synchronize(@Render);
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  ourBall:=TControlledBall.create(400,300,50);
  renderer:=TRenderThread.Create(false,@Image1);
  renderer.renderW:=800;
  renderer.renderH:=600;
  ourBall.xArea:=renderer.renderW;
  ourBall.yArea:=renderer.renderH;
  ourBall.r=5;
  renderer.refBall:=@ourBall;
  renderer.Start;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if ((Key=Ord('A')) or (key=ord('a'))) then
  begin
    ourBall.mkx:=-1;
  end;
    if ((Key=ord('D')) or (key=ord('d'))) then
  begin
    ourBall.mkx:=1;
  end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if ((Key=ord('A')) or (key=ord('a'))) then
  begin
    ourBall.mkx:=0;
  end;
    if ((Key=ord('D')) or (key=ord('d'))) then
  begin
    ourBall.mkx:=0;
  end;
end;

procedure TForm1.PaintBox1Click(Sender: TObject);
begin

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  renderer.run:=false;
  renderer.Terminate;
end;

end.

