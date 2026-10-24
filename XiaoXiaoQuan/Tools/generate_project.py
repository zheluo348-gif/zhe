from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
proj=ROOT/'XiaoXiaoQuan.xcodeproj';proj.mkdir(exist_ok=True)
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
objects=[]
def obj(key,body):
 i=uid(key);objects.append(f'{i} = {{ {body} }};');return i
sources=sorted((ROOT/'Sources').glob('*.swift'))
tests=sorted((ROOT/'Tests').glob('*.swift'))
refs=[];builds=[]
for f in sources:
 refs.append(obj('ref'+f.name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Sources/{f.name}"; sourceTree = "<group>";'))
 builds.append(obj('build'+f.name, f'isa = PBXBuildFile; fileRef = {refs[-1]};'))
testrefs=[];testbuilds=[]
for f in tests:
 testrefs.append(obj('ref'+f.name,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Tests/{f.name}"; sourceTree = "<group>";'))
 testbuilds.append(obj('build'+f.name,f'isa = PBXBuildFile; fileRef = {testrefs[-1]};'))
assetref=obj('assets','isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Resources/Assets.xcassets; sourceTree = "<group>";')
assetbuild=obj('assetbuild',f'isa = PBXBuildFile; fileRef = {assetref};')
product=obj('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = XiaoXiaoQuan.app; sourceTree = BUILT_PRODUCTS_DIR;')
testproduct=obj('testproduct','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = XiaoXiaoQuanUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
pg=obj('products',f'isa = PBXGroup; children = ({product},{testproduct},); name = Products; sourceTree = "<group>";')
main=obj('main',f'isa = PBXGroup; children = ({",".join(refs+testrefs+[assetref,pg])},); sourceTree = "<group>";')
sp=obj('sourcephase',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(builds)},); runOnlyForDeploymentPostprocessing = 0;')
rp=obj('resourcephase',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetbuild},); runOnlyForDeploymentPostprocessing = 0;')
fp=obj('frameworkphase','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
tsp=obj('testsourcephase',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(testbuilds)},); runOnlyForDeploymentPostprocessing = 0;')
tfp=obj('testframeworkphase','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
def configlist(prefix,settings):
 configs=[]
 for mode in ['Debug','Release']:
  flags='SWIFT_OPTIMIZATION_LEVEL = "-Onone"; GCC_OPTIMIZATION_LEVEL = 0; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES;' if mode=='Debug' else 'SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
  configs.append(obj(prefix+mode,f'isa = XCBuildConfiguration; name = {mode}; buildSettings = {{ {settings} {flags} }};'))
 return obj(prefix+'list',f'isa = XCConfigurationList; buildConfigurations = ({",".join(configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common='CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 5.0; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; TARGETED_DEVICE_FAMILY = 1;'
pcl=configlist('projectconfig',common)
acl=configlist('appconfig',common+' PRODUCT_NAME = XiaoXiaoQuan; PRODUCT_BUNDLE_IDENTIFIER = com.xinbei.xiaoxiaoquan.preview; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = "小小圈"; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait; INFOPLIST_KEY_NSMicrophoneUsageDescription = "由你主动录音，试听后发送语音便签。"; INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "由你选择一张照片，添加到本机聊天记录。"; MARKETING_VERSION = 0.4.1; CURRENT_PROJECT_VERSION = 6; CODE_SIGN_STYLE = Automatic; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; SWIFT_EMIT_LOC_STRINGS = YES;')
tcl=configlist('testconfig',common+' PRODUCT_NAME = XiaoXiaoQuanUITests; PRODUCT_BUNDLE_IDENTIFIER = com.xinbei.xiaoxiaoquan.preview.uitests; GENERATE_INFOPLIST_FILE = YES; TEST_TARGET_NAME = XiaoXiaoQuan; CODE_SIGN_STYLE = Automatic;')
app=uid('apptarget');project=uid('project')
proxy=obj('proxy',f'isa = PBXContainerItemProxy; containerPortal = {project}; proxyType = 1; remoteGlobalIDString = {app}; remoteInfo = XiaoXiaoQuan;')
dep=obj('dependency',f'isa = PBXTargetDependency; target = {app}; targetProxy = {proxy};')
obj('apptarget',f'isa = PBXNativeTarget; buildConfigurationList = {acl}; buildPhases = ({sp},{fp},{rp},); buildRules = (); dependencies = (); name = XiaoXiaoQuan; productName = XiaoXiaoQuan; productReference = {product}; productType = "com.apple.product-type.application";')
testtarget=obj('testtarget',f'isa = PBXNativeTarget; buildConfigurationList = {tcl}; buildPhases = ({tsp},{tfp},); buildRules = (); dependencies = ({dep},); name = XiaoXiaoQuanUITests; productName = XiaoXiaoQuanUITests; productReference = {testproduct}; productType = "com.apple.product-type.bundle.ui-testing";')
obj('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2600; TargetAttributes = {{ {app} = {{ CreatedOnToolsVersion = 26.0; }}; {testtarget} = {{ CreatedOnToolsVersion = 26.0; TestTargetID = {app}; }}; }}; }}; buildConfigurationList = {pcl}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = ("zh-Hans", en, Base,); mainGroup = {main}; productRefGroup = {pg}; projectDirPath = ""; projectRoot = ""; targets = ({app},{testtarget},);')
(proj/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {project}; }}\n')
schemedir=proj/'xcshareddata/xcschemes';schemedir.mkdir(parents=True,exist_ok=True)
def ref(i,name,product): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{i}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:XiaoXiaoQuan.xcodeproj"/>'
a=ref(app,'XiaoXiaoQuan','XiaoXiaoQuan.app');t=ref(testtarget,'XiaoXiaoQuanUITests','XiaoXiaoQuanUITests.xctest')
(schemedir/'XiaoXiaoQuan.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{a}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{t}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{a}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{a}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(proj)
