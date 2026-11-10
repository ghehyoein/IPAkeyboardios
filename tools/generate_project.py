"""Generate a self-contained Xcode project using only Python's standard library."""
import hashlib, json, plistlib, os
from pathlib import Path
R = Path(__file__).resolve().parents[1]
P = R/'IPAKeyboard.xcodeproj'
P.mkdir(exist_ok=True)
bundle_id=os.environ.get('IPA_BUNDLE_IDENTIFIER', 'org.example.IPAKeyboard')
app_group=os.environ.get('IPA_APP_GROUP_IDENTIFIER', 'group.org.example.IPAKeyboard')
version=os.environ.get('IPA_MARKETING_VERSION', '0.4.0')
build_number=os.environ.get('IPA_BUILD_NUMBER', '4')
objects={}
def ident(name): return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(token, **attrs):
 i=ident(token); objects[i]=attrs; return i

def plist(path, data):
 with (R/path).open('wb') as f: plistlib.dump(data, f, sort_keys=False)
base={'CFBundleDevelopmentRegion':'en','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'$(PRODUCT_NAME)','CFBundleShortVersionString':version,'CFBundleVersion':build_number,'IPASettingsAppGroup':'$(IPA_APP_GROUP_IDENTIFIER)'}
plist('App/Info.plist', dict(base,CFBundlePackageType='APPL',CFBundleDisplayName='IPA Keyboard',ITSAppUsesNonExemptEncryption=False,LSRequiresIPhoneOS=True,UILaunchScreen={},UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],**{'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}))
plist('KeyboardExtension/Info.plist',dict(base,CFBundlePackageType='XPC!',CFBundleDisplayName='IPA Keyboard',NSExtension={'NSExtensionPointIdentifier':'com.apple.keyboard-service','NSExtensionPrincipalClass':'$(PRODUCT_MODULE_NAME).KeyboardViewController','NSExtensionAttributes':{'IsASCIICapable':True,'PrefersRightToLeft':False,'PrimaryLanguage':'mul','RequestsOpenAccess':True}}))
for file in ['App/IPAKeyboard.entitlements','KeyboardExtension/IPAKeyboardExtension.entitlements']:
 plist(file,{'com.apple.security.application-groups':['$(IPA_APP_GROUP_IDENTIFIER)']})
shared=['Shared/SwipePreferences.swift','Shared/KeyboardMaterial.swift','Shared/KeyFeedback.swift','Shared/SymbolVisibility.swift','Shared/IPACatalog.swift','Shared/KeyboardLayout.swift','Shared/LetterKey.swift','Shared/KeyboardSurface.swift','Shared/VariantStrip.swift','Shared/SymbolGrid.swift']
source_sets={'IPAKeyboard':['App/AppDelegate.swift','App/SandboxViewController.swift','App/SymbolSettingsViewController.swift','App/SymbolCatalogViewController.swift','App/SwipeSettingsViewController.swift']+shared,'IPAKeyboardExtension':['KeyboardExtension/KeyboardViewController.swift']+shared,'IPAKeyboardTests':['Tests/KeyboardTests.swift'],'IPAKeyboardUITests':['Tests/KeyboardUITests.swift']}
files=sorted(set(sum(source_sets.values(),[])+['Shared/PrivacyInfo.xcprivacy','Shared/ipa-catalog.json','App/Info.plist','KeyboardExtension/Info.plist','App/Assets.xcassets','App/IPAKeyboard.entitlements','KeyboardExtension/IPAKeyboardExtension.entitlements']))
refs={}
for file in files:
 ext=Path(file).suffix
 refs[file]=add('file:'+file,isa='PBXFileReference',lastKnownFileType={'.swift':'sourcecode.swift','.json':'text.json','.plist':'text.plist.xml','.entitlements':'text.plist.entitlements','.xcassets':'folder.assetcatalog','.xcprivacy':'text.xml'}[ext],path=file,sourceTree='<group>')
products={}
for target,extension,typ in [('IPAKeyboard','app','wrapper.application'),('IPAKeyboardExtension','appex','wrapper.app-extension'),('IPAKeyboardTests','xctest','wrapper.cfbundle'),('IPAKeyboardUITests','xctest','wrapper.cfbundle')]:
 products[target]=add('product:'+target,isa='PBXFileReference',explicitFileType=typ,includeInIndex=0,path=target+'.'+extension,sourceTree='BUILT_PRODUCTS_DIR')
productGroup=add('products',isa='PBXGroup',children=list(products.values()),name='Products',sourceTree='<group>')
mainGroup=add('mainGroup',isa='PBXGroup',children=list(refs.values())+[productGroup],sourceTree='<group>')
def configs(name, settings):
 ids=[]
 for mode in ['Debug','Release']:
  opts=dict(settings)
  profile = os.environ.get({'IPAKeyboard':'APP_PROFILE_UUID','IPAKeyboardExtension':'EXT_PROFILE_UUID'}.get(name, ''))
  if mode=='Release' and profile:
   opts.update(CODE_SIGN_STYLE='Manual',CODE_SIGN_IDENTITY='Apple Distribution',DEVELOPMENT_TEAM=os.environ['APPLE_TEAM_ID'],PROVISIONING_PROFILE_SPECIFIER=profile)
  opts['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if mode=='Debug' else '-O'
  if mode=='Debug': opts['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'; opts['ENABLE_TESTABILITY']='YES'
  ids.append(add(name+mode,isa='XCBuildConfiguration',buildSettings=opts,name=mode))
 return add(name+'configs',isa='XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
projectSettings={'IPA_APP_GROUP_IDENTIFIER':app_group,'IPHONEOS_DEPLOYMENT_TARGET':'26.0','SDKROOT':'iphoneos','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','SWIFT_STRICT_CONCURRENCY':'minimal','TARGETED_DEVICE_FAMILY':'1','CODE_SIGN_STYLE':'Automatic'}
projectConfigs=configs('project',projectSettings)
for target,fileset in source_sets.items():
 sources=[]
 for file in fileset:
  sources.append(add(target+':source:'+file,isa='PBXBuildFile',fileRef=refs[file]))
 resource=add(target+':resource',isa='PBXBuildFile',fileRef=refs['Shared/ipa-catalog.json'])
 phases=[add(target+':sources',isa='PBXSourcesBuildPhase',buildActionMask=2147483647,files=sources,runOnlyForDeploymentPostprocessing=0),add(target+':resources',isa='PBXResourcesBuildPhase',buildActionMask=2147483647,files=[resource],runOnlyForDeploymentPostprocessing=0),add(target+':frameworks',isa='PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)]
 if target in ['IPAKeyboard','IPAKeyboardExtension']:
  privacy=add(target+':privacy',isa='PBXBuildFile',fileRef=refs['Shared/PrivacyInfo.xcprivacy'])
  objects[phases[1]]['files'].append(privacy)
 dependencies=[]
 settings={'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':bundle_id if target=='IPAKeyboard' else bundle_id+'.'+target,'CURRENT_PROJECT_VERSION':build_number,'MARKETING_VERSION':version,'LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks']}
 if target=='IPAKeyboard':
  settings['INFOPLIST_FILE']='App/Info.plist'
  settings['CODE_SIGN_ENTITLEMENTS']='App/IPAKeyboard.entitlements'
  settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
  iconResource=add(target+':icon',isa='PBXBuildFile',fileRef=refs['App/Assets.xcassets'])
  objects[phases[1]]['files'].append(iconResource)
  embed=add('embedExtension',isa='PBXBuildFile',fileRef=products['IPAKeyboardExtension'],settings={'ATTRIBUTES':['RemoveHeadersOnCopy']})
  phases.append(add('embedExtensions',isa='PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=13,files=[embed],name='Embed App Extensions',runOnlyForDeploymentPostprocessing=0))
  proxy=add('extensionProxy',isa='PBXContainerItemProxy',containerPortal=ident('project'),proxyType=1,remoteGlobalIDString=ident('target:IPAKeyboardExtension'),remoteInfo='IPAKeyboardExtension')
  dependencies.append(add('extensionDependency',isa='PBXTargetDependency',target=ident('target:IPAKeyboardExtension'),targetProxy=proxy))
  productType='com.apple.product-type.application'
 elif target=='IPAKeyboardExtension':
  settings.update(INFOPLIST_FILE='KeyboardExtension/Info.plist',APPLICATION_EXTENSION_API_ONLY='YES',SKIP_INSTALL='YES',LD_RUNPATH_SEARCH_PATHS=['$(inherited)','@executable_path/Frameworks','@executable_path/../../Frameworks'])
  settings['PRODUCT_BUNDLE_IDENTIFIER']=bundle_id+'.Keyboard'
  settings['CODE_SIGN_ENTITLEMENTS']='KeyboardExtension/IPAKeyboardExtension.entitlements'
  productType='com.apple.product-type.app-extension'
 else:
  settings.update(GENERATE_INFOPLIST_FILE='YES',TEST_HOST='$(BUILT_PRODUCTS_DIR)/IPAKeyboard.app/IPAKeyboard',BUNDLE_LOADER='$(TEST_HOST)')
  if target=='IPAKeyboardUITests':
   settings.pop('TEST_HOST'); settings.pop('BUNDLE_LOADER'); settings['TEST_TARGET_NAME']='IPAKeyboard'
  proxy=add(target+'testHostProxy',isa='PBXContainerItemProxy',containerPortal=ident('project'),proxyType=1,remoteGlobalIDString=ident('target:IPAKeyboard'),remoteInfo='IPAKeyboard')
  dependencies.append(add(target+'testHostDependency',isa='PBXTargetDependency',target=ident('target:IPAKeyboard'),targetProxy=proxy))
  productType='com.apple.product-type.bundle.ui-testing' if target=='IPAKeyboardUITests' else 'com.apple.product-type.bundle.unit-test'
 add('target:'+target,isa='PBXNativeTarget',buildConfigurationList=configs(target,settings),buildPhases=phases,buildRules=[],dependencies=dependencies,name=target,productName=target,productReference=products[target],productType=productType)
add('project',isa='PBXProject',attributes={'LastUpgradeCheck':'1600','BuildIndependentTargetsInParallel':'YES'},buildConfigurationList=projectConfigs,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','zh-Hans','Base'],mainGroup=mainGroup,productRefGroup=productGroup,projectDirPath='',projectRoot='',targets=[ident('target:'+t) for t in source_sets])
def encode(v,indent=0):
 if isinstance(v,dict):
  return '{\n'+''.join('\t'*(indent+1)+json.dumps(k)+' = '+encode(val,indent+1)+';\n' for k,val in v.items())+'\t'*indent+'}'
 if isinstance(v,list): return '('+', '.join(encode(x,indent) for x in v)+')'
 if isinstance(v,int): return str(v)
 return json.dumps(v,ensure_ascii=False)
(P/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode(dict(archiveVersion=1,classes={},objectVersion=56,objects=objects,rootObject=ident('project')))+'\n')
scheme=P/'xcshareddata'/'xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
def ref(t,ext): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident("target:"+t)}" BuildableName="{t}.{ext}" BlueprintName="{t}" ReferencedContainer="container:IPAKeyboard.xcodeproj"/>'
(scheme/'IPAKeyboard.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('IPAKeyboard','app')}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('IPAKeyboardTests','xctest')}</TestableReference><TestableReference skipped="NO">{ref('IPAKeyboardUITests','xctest')}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('IPAKeyboard','app')}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('IPAKeyboard','app')}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated IPAKeyboard.xcodeproj, shared scheme and Info.plists.')
