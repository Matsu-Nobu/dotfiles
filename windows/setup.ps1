# Windows の開発環境をそろえる入口。WezTerm の開発版とフォントを Windows に入れ、残りは WSL の Ubuntu の中で setup.sh に任せる。
# 各段階は、既に済んでいるかを先に調べ、済んでいれば何もしない。そのため何度実行してもよい。
# Windows に標準で入っている PowerShell 5.1 で動くように、PowerShell 7 だけの構文を使わない。
#
# 使い方:
#   powershell -ExecutionPolicy Bypass -File setup.ps1 -Repo <GitHub のユーザー名>/dotfiles
param(
    [string]$Repo = ""
)

$ErrorActionPreference = "Stop"
# wsl.exe は既定で UTF-16 で出力するので、文字列として比べられるよう UTF-8 で出力させる。
$env:WSL_UTF8 = "1"

$Distro = "Ubuntu"
$FontName = "MesloLGS Nerd Font Mono"

function Write-Stage([string]$Name) {
    Write-Host ""
    Write-Host "== $Name =="
}

function Write-Did([string]$Message) {
    Write-Host "実行した: $Message"
}

function Write-Skipped([string]$Message) {
    Write-Host "飛ばした: $Message"
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 管理者の権限が要る段階で、管理者として同じスクリプトを開き直す。
function Request-Admin([string]$Reason) {
    Write-Host "$Reason には管理者の権限が要ります。管理者として、このスクリプトを開き直します。"
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Repo -ne "") {
        $arguments += " -Repo `"$Repo`""
    }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $arguments
    exit 0
}

function Invoke-Wsl([string]$Command) {
    & wsl.exe -d $Distro -- bash -lc $Command
    if ($LASTEXITCODE -ne 0) {
        throw "WSL の中のコマンドが失敗しました: $Command"
    }
}

function Install-WslUbuntu {
    Write-Stage "WSL と Ubuntu"
    $distros = ""
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
        $distros = (& wsl.exe -l -q 2>$null) -join "`n"
    }
    if ($distros -match "(?m)^$Distro\s*$") {
        Write-Skipped "WSL の $Distro は入っている"
    } else {
        if (-not (Test-Admin)) {
            Request-Admin "WSL と $Distro のインストール"
        }
        & wsl.exe --install -d $Distro
        if ($LASTEXITCODE -ne 0) {
            throw "wsl --install -d $Distro が失敗しました"
        }
        Write-Did "WSL と $Distro を入れた"
        Write-Host "Windows を再起動し、スタートメニューから $Distro を開いてユーザーを作ってから、もう一度このスクリプトを実行してください。"
        exit 0
    }

    $user = (& wsl.exe -d $Distro -- whoami 2>$null) -join ""
    if ($LASTEXITCODE -ne 0 -or $user -eq "" -or $user -eq "root") {
        Write-Host "$Distro のユーザーがまだ作られていません。スタートメニューから $Distro を開いてユーザーを作ってから、もう一度このスクリプトを実行してください。"
        exit 1
    }
    return $user.Trim()
}

function Install-WezTerm {
    Write-Stage "WezTerm"
    $exe = Join-Path $env:ProgramFiles "WezTerm\wezterm.exe"
    if (Test-Path $exe) {
        Write-Skipped "WezTerm は入っている ($exe)"
        return
    }
    # 正式版は通知を表示できないので、GitHub の nightly リリースの開発版を入れる。
    $installer = Join-Path $env:TEMP "WezTerm-nightly-setup.exe"
    Invoke-WebRequest -Uri "https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe" -OutFile $installer -UseBasicParsing
    $process = Start-Process -FilePath $installer -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait -PassThru
    Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
    if ($process.ExitCode -ne 0) {
        throw "WezTerm の開発版のインストーラが失敗しました (終了コード $($process.ExitCode))"
    }
    Write-Did "WezTerm の開発版を入れた"
}

function Install-Font {
    Write-Stage "フォント"
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    $registry = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    $installed = Get-ItemProperty -Path $registry -ErrorAction SilentlyContinue |
        Get-Member -MemberType NoteProperty |
        Where-Object { $_.Name -like "$FontName*" }
    if ($installed) {
        Write-Skipped "$FontName は入っている"
        return
    }

    $tmp = Join-Path $env:TEMP ("meslo-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp "Meslo.zip"
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $tmp
        New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
        if (-not (Test-Path $registry)) {
            New-Item -Path $registry -Force | Out-Null
        }
        # ユーザーのフォントのフォルダに置き、レジストリに登録すると、管理者の権限なしでそのユーザーだけが使える。
        $files = Get-ChildItem -Path $tmp -Filter "MesloLGSNerdFontMono-*.ttf"
        if (-not $files) {
            throw "Meslo.zip に MesloLGSNerdFontMono-*.ttf がありませんでした"
        }
        foreach ($file in $files) {
            $dest = Join-Path $fontDir $file.Name
            Copy-Item -Path $file.FullName -Destination $dest -Force
            $style = $file.BaseName -replace "^MesloLGSNerdFontMono-", ""
            New-ItemProperty -Path $registry -Name "$FontName $style (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
        }
        Write-Did "$FontName を $fontDir に入れた"
    } finally {
        Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-DotfilesSetup {
    Write-Stage "WSL の中の dotfiles"
    & wsl.exe -d $Distro -- bash -lc "test -d ~/dotfiles"
    if ($LASTEXITCODE -eq 0) {
        Write-Skipped "WSL の ~/dotfiles はある"
    } else {
        if ($Repo -eq "") {
            $script:Repo = Read-Host "clone するリポジトリ (<GitHub のユーザー名>/dotfiles)"
        }
        Write-Host "WSL の中に gh を入れるため、Ubuntu の sudo のパスワードを尋ねることがあります。"
        Invoke-Wsl "command -v gh >/dev/null || (sudo apt-get update && sudo apt-get install -y gh)"
        Write-Host "gh auth login を実行します。画面の案内に従って GitHub にログインしてください。"
        Invoke-Wsl "gh auth status >/dev/null 2>&1 || gh auth login"
        Invoke-Wsl "gh repo clone '$Repo' ~/dotfiles"
        Write-Did "WSL の ~/dotfiles に $Repo を clone した"
    }
    Write-Host "WSL の中で ~/dotfiles/setup.sh を実行します。"
    Invoke-Wsl "cd ~/dotfiles && ./setup.sh"
}

function Write-WezTermConfig([string]$WslUser) {
    Write-Stage "WezTerm の設定の入口"
    $template = "\\wsl.localhost\$Distro\home\$WslUser\dotfiles\windows\wezterm.lua"
    $dest = Join-Path $env:USERPROFILE ".wezterm.lua"
    $content = (Get-Content -Path $template -Raw -Encoding UTF8).Replace("__WSL_USER__", $WslUser)
    if ((Test-Path $dest) -and ((Get-Content -Path $dest -Raw -Encoding UTF8) -eq $content)) {
        Write-Skipped "$dest は最新"
        return
    }
    # PowerShell 5.1 の Set-Content -Encoding UTF8 は BOM を付けるので、BOM なしの UTF-8 で書く。
    [IO.File]::WriteAllText($dest, $content, (New-Object Text.UTF8Encoding($false)))
    Write-Did "$dest を書いた"
}

$wslUser = Install-WslUbuntu
Install-WezTerm
Install-Font
Invoke-DotfilesSetup
Write-WezTermConfig $wslUser
Write-Host ""
Write-Host "setup.ps1: 終わりました。"
