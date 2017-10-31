--//
--// * Installer for Freya
--// | Literally doesn't need to worry about any form of preservation at all.
--// | Just unpack and call it a day.
--//

SS = game.ServerStorage
SSS = game.ServerScriptService
RS = game.ReplicatedStorage
RF = game.ReplicatedFirst
SP = game.StarterPlayer
SPS = SP.StarterPlayerScripts

=>
  -- Skeleton
  print "[Freya Installer] Creating Freya structure"

  -- SS
  F_SS = with Instance.new "Folder"
    .Name = "Freya"
    .Parent = SS

  FC_SS = with Instance.new "Folder"
    .Name = "Components"
    .Parent = F_SS

  FC_Studio = with Instance.new "Folder"
    .Name = "Studio"
    .Parent = FC_SS

  FC_Server = with Instance.new "Folder"
    .Name = "Server"
    .Parent = FC_SS

  -- SSS
  FS_SSS = with Instance.new "Folder"
    .Name = "FreyaScripts"
    .Parent = SSS

  with Instance.new "Folder"
    .Name = "User"
    .Parent = FS_SSS

  -- RS
  F_RS = with Instance.new "Folder"
    .Name = "Freya"
    .Parent = RS

  FC_RS = with Instance.new "Folder"
    .Name = "Components"
    .Parent = F_RS

  FC_Shared = with Instance.new "Folder"
    .Name = "Shared"
    .Parent = FC_RS

  FC_Client = with Instance.new "Folder"
    .Name = "Client"
    .Parent = FC_RS

  -- RF
  FS_RF = with Instance.new "Folder"
    .Name = "FreyaScripts"
    .Parent = RF

  with Instance.new "Folder"
    .Name = "User"
    .Parent = FS_RF

  -- SPS
  FS_SPS = with Instance.new "Folder"
    .Name = "FreyaScripts"
    .Parent = SPS

  with Instance.new "Folder"
    .Name = "User"
    .Parent = FS_SPS


  -- Standards (Shared)
  print "[Freya Installer] Unpacking standard components:"

  for v in *@Standard\GetChildren!
    print "[Freya Installer] * #{v.Name}"
    v.Parent = FC_Shared


  -- Studio
  print "[Freya Installer] Unpacking Studio components:"

  for v in *@Core.Studio\GetChildren!
    print "[Freya Installer] * #{v.Name}"
    v.Parent = FC_Studio


  -- Main
  print "[Freya Installer] Unpacking Freya controllers"

  with @Core.Main.Client
    .Name = "Main"
    .Parent = F_RS

  with @Core.Main.Server
    .Name = "Main"
    .Parent = F_SS

  with @Core.Main.Studio
    .Name = "FreyaStudio"
    .Parent = F_SS


  -- Loaders
  print "[Freya Installer] Unpacking Freya loaders"

  with @Core.Loaders.PlayerScripts
    .Name = "FreyaLoader"
    .Parent = SPS

  with @Core.Loaders.ReplicatedFirst
    .Name = "FreyaLoader"
    .Parent = RF

  with @Core.Loaders.ServerScriptService
    .Name = "FreyaLoader"
    .Parent = SSS

  print "[Freya Installer] Finished installing Freya"
