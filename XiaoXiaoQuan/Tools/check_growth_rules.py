from pathlib import Path
import re
from swift_rules import run_checks
root=Path(__file__).resolve().parents[2]
src=root/'XiaoXiaoQuan/Sources'
models=(src/'Models.swift').read_text().split('@MainActor final class CircleStore')[0].replace('import SwiftUI','import Foundation')
creative=(src/'CreativeModels.swift').read_text().split('struct AIReply')[0].replace('import SwiftUI','').replace('import UIKit','')
play=(src/'PlaygroundModels.swift').read_text().replace('import SwiftUI','')
growth=(src/'GrowthModels.swift').read_text().replace('import SwiftUI','')
growth=re.sub(r'    var (sky|floor|accent|onPaperAccent): Color \{[^\n]+\}\n','',growth)
def function(source, name):
 start=source.index('    func '+name);brace=source.index('{',start);level=1;i=brace+1
 while level:
  if source[i]=='{':level+=1
  elif source[i]=='}':level-=1
  i+=1
 return source[start:i]
store='''
@MainActor final class CircleStore {
 var state = SavedState()
 var collected = 0
 var friends:Bool { state.mode == "friends" }
 var current:SpaceData { friends ? state.friends:state.couple }
 var creative:CreativeSpace { current.creative ?? CreativeSpace() }
 init() { state.couple.playground=PlaygroundData();state.friends.playground=PlaygroundData();state.couple.growth=GrowthState();state.friends.growth=GrowthState() }
 func update(_ change:(inout SpaceData)->Void) { if friends { change(&state.friends) } else { change(&state.couple) } }
 func updateCreative(_ change:(inout CreativeSpace)->Void) { update { var c=$0.creative ?? CreativeSpace();change(&c);$0.creative=c } }
 func persist() {}
 func collectSticker(pose:Int,caption:String) { collected += 1 }
'''+function((src/'Models.swift').read_text(),'send(')+'\n'+function((src/'CreativeModels.swift').read_text(),'startQuiz(')+'\n}\n'
service=(src/'CreativeModels.swift').read_text().split('struct AIReply')[1].split('@MainActor extension CircleStore')[0]
service='struct AIReply'+service
choice=(src/'AIChoiceViews.swift').read_text().split('struct AIAvailabilityNote')[0].replace('import SwiftUI','')
shared=(src/'SharedDrawingStore.swift').read_text()
tests=r'''
@main struct Checks {
 @MainActor static func main() async throws {
 var checks=0
 func check(_ value:@autoclosure()->Bool,_ reason:String) { precondition(value(),reason);checks += 1 }
 let boundaries=[(0,1),(1,1),(2,2),(3,3),(6,3),(7,7),(9,7),(10,10),(29,10),(30,30),(59,30),(60,60),(89,60),(90,90),(99,90),(100,90),(119,90),(120,120),(150,150),(179,150),(180,180),(359,330),(360,360),(365,360),(390,390),(900,900)]
 for (day,want) in boundaries { check(GrowthStage.at(day).day==want,"stage boundary") }
 check(Set(GrowthStage.all.map(\.kind)).count==GrowthStage.all.count,"unique scenes")
 check(Set(GrowthStage.all.map(\.title)).count==GrowthStage.all.count,"unique names")
 for period in 1...48 {
  let day=period*30,stage=GrowthStage.at(day)
  check(stage.day==day && stage.next?.day==day+30,"monthly progression continues")
  check(GrowthStage.at(day-1).day==(period==1 ? 10:day-30),"monthly previous boundary")
  check(GrowthStage.exact(day)?.day==day && GrowthStage.exact(day+1)==nil,"only earned exact milestones")
 }
 check(GrowthStage.monthly(13).variation==1 && GrowthStage.monthly(13).skyHex != GrowthStage.monthly(1).skyHex,"second season has its own palette")
 let s=CircleStore();let base=Calendar.current.startOfDay(for:Date(timeIntervalSince1970:1792800000))
 s.recordVisit(base);check(s.growth.visits.isEmpty,"no visit before entry")
 s.state.entered=true;s.recordVisit(base);s.recordVisit(base.addingTimeInterval(3600));check(s.growth.visits.count==1,"one visit per day")
 for i in 1..<10 { s.recordVisit(base.addingTimeInterval(Double(i*3)*86400)) }
 check(s.growthDays==10 && s.stage.day==10,"gaps do not erase growth")
 let progress=s.growth.visits;_ = GrowthStage.at(365);check(s.growth.visits==progress,"preview is pure")
 s.state.mode="friends";check(s.growth.visits.isEmpty,"separate space growth");s.recordVisit(base);check(s.growthDays==1,"friend first day")
 s.state.mode="couple";check(s.growthDays==10,"couple growth retained")
 s.setProfile("Candy",photo:nil,space:"Our House",pet:"Mochi",favorites:["capsules"])
 check(s.myName=="Candy" && s.growth.spaceName=="Our House" && s.petName=="Mochi","profile saved")
 s.setProfile("阿哲",photo:nil,space:"Bad",pet:"Bad",favorites:[]);check(s.myName=="Candy" && s.growth.spaceName=="Our House","duplicate name rejected")
 s.sendChargedHug(level:0);check(s.current.messages.last?.kind=="hug:1","lower hug clamp")
 s.sendChargedHug(level:7);check(s.current.messages.last?.kind=="hug:3" && s.current.messages.last?.sender=="Candy","upper hug clamp and nickname")
 s.inviteToPlay(.story);let story=s.current.messages.last!.id
 s.finishInvitation(story);check(s.current.messages.last?.invitation?.state=="等你来玩","cannot finish empty story")
 s.updatePlay { $0.story.append("A tiny moon arrived.") };s.finishInvitation(story);check(s.current.messages.last?.invitation?.state=="等你来玩","must accept first")
 s.acceptInvitation(story);s.finishInvitation(story);let summary=s.current.messages.last?.invitation?.summary
 check(s.current.messages.last?.invitation?.state=="收好小回忆" && summary?.contains("A tiny moon arrived.")==true,"story result stored on invite")
 s.updatePlay { $0.story.append("Another sentence") };s.finishInvitation(story);check(s.current.messages.last?.invitation?.summary==summary,"finished result immutable")
 s.inviteToPlay(.quiz);s.acceptInvitation(s.current.messages.last!.id);check(s.creative.quiz?.players==["Candy","阿哲"],"quiz uses participants")
 s.inviteToPlay(.gomoku);let chess=s.current.messages.last!.id;s.acceptInvitation(chess);s.finishInvitation(chess);check(s.current.messages.last?.invitation?.state=="一起玩着","unfinished board cannot submit")
 s.updatePlay { for cell in [0,9,1,10,2,11,3,12,4] { $0.gomoku.place(cell) } };s.finishInvitation(chess);check(s.current.messages.last?.invitation?.summary?.contains("9步")==true,"board result stored")
 let beforeVisits=s.growth.visits
 s.useWallpaper(1);check(s.stage.day==1 && s.growthStage.day==10 && s.growth.visits==beforeVisits,"old wallpaper preserves progress")
 s.useWallpaper(30);check(s.stage.day==1,"locked wallpaper rejected")
 s.useWallpaper(4);check(s.stage.day==1,"non-milestone wallpaper rejected")
 s.state.mode="friends";check(s.growth.selectedWallpaperDay==nil,"wallpaper choice is space-specific");s.state.mode="couple"
 let selected=try JSONDecoder().decode(SavedState.self,from:JSONEncoder().encode(s.state));check(selected.couple.growth?.selectedWallpaperDay==1,"wallpaper selection persists")
 s.followNewestWallpaper();check(s.stage.day==10 && s.growth.selectedWallpaperDay==nil,"follow newest restores real growth scene")
 check(!s.isAIEnabled,"AI defaults off")
 do { _ = try await s.generateCreative(prompt:"hello",mode:"text");preconditionFailure("AI off must reject") } catch CreativeServiceError.disabled { checks += 1 }
 do { _ = try await CreativeService().generate(prompt:"hello",mode:"text",space:"couple");preconditionFailure("service opt in required") } catch CreativeServiceError.disabled { checks += 1 }
 s.setAIEnabled(true);check(s.isAIEnabled,"user can opt in")
 let opted=try JSONDecoder().decode(SavedState.self,from:JSONEncoder().encode(s.state));check(opted.aiEnabled==true,"AI choice persists")
 do { _ = try await s.generateCreative(prompt:"hello",mode:"text");preconditionFailure("unconfigured service must reject") } catch CreativeServiceError.notConnected { checks += 1 }
 s.setAIEnabled(false);check(!s.isAIEnabled && s.growth.visits==beforeVisits,"turning AI off preserves basic data")
 let bytes=try JSONEncoder().encode(s.state);let decoded=try JSONDecoder().decode(SavedState.self,from:bytes)
 check(decoded.couple.growth?.visits.count==10 && decoded.profile?.nickname=="Candy" && decoded.couple.messages.last?.invitation?.summary != nil,"round trip progress and results")
 var legacy=try JSONSerialization.jsonObject(with:bytes) as! [String:Any];legacy.removeValue(forKey:"profile")
 for key in ["couple","friends"] { var space=legacy[key] as! [String:Any];space.removeValue(forKey:"growth");legacy[key]=space }
 let old=try JSONDecoder().decode(SavedState.self,from:JSONSerialization.data(withJSONObject:legacy))
 check(old.profile==nil && old.couple.growth==nil && old.couple.messages.count==s.state.couple.messages.count,"legacy schema decodes")
 let drawingStore=CircleStore()
 drawingStore.send("ordinary message")
 let untouched=drawingStore.current.messages[0]
 let drawingID=drawingStore.startSharedDrawing()
 check(drawingStore.current.messages.count==2 && drawingStore.current.messages.last?.sharedDrawing?.players==drawingStore.memberNames,"shared drawing starts in chat with current participants")
 check(drawingStore.current.messages.last?.sharedDrawing?.currentPlayer==drawingStore.myName,"author starts first round")
 check(!drawingStore.finishSharedDrawing(drawingID,revision:0),"cannot finish an empty drawing")
 check(!drawingStore.submitDrawingRound(drawingID,drawing:Data(),note:" \n ",revision:0),"blank rounds rejected")
 let ink=Data([1,2,3])
 check(drawingStore.submitDrawingRound(drawingID,drawing:ink,note:"A cat",revision:0),"first contribution accepted")
 check(drawingStore.current.messages.last?.sharedDrawing?.currentPlayer=="阿哲","turn passes to partner")
 check(!drawingStore.submitDrawingRound(drawingID,drawing:ink,note:"duplicate",revision:0),"stale and duplicate submissions rejected")
 check(!drawingStore.finishSharedDrawing(drawingID,revision:1),"both participants contribute before finishing")
 check(drawingStore.submitDrawingRound(drawingID,drawing:Data(),note:"A little fish",revision:1),"second participant can add a note")
 check(drawingStore.current.messages.last?.sharedDrawing?.rounds.map(\.author)==[drawingStore.myName,"阿哲"],"each round keeps its author")
 check(drawingStore.current.messages.last?.sharedDrawing?.rounds[0].drawing==ink,"previous ink preserved")
 check(!drawingStore.finishSharedDrawing(drawingID,revision:1),"stale completion rejected")
 check(drawingStore.finishSharedDrawing(drawingID,revision:2),"two-participant work can finish")
 check(!drawingStore.finishSharedDrawing(drawingID,revision:2),"completion is idempotent")
 check(!drawingStore.submitDrawingRound(drawingID,drawing:ink,note:"late",revision:2),"finished drawing immutable")
 check(drawingStore.current.messages[0]==untouched,"ordinary history preserved")
 let roundTrip=try JSONDecoder().decode(SavedState.self,from:JSONEncoder().encode(drawingStore.state))
 check(roundTrip.couple.messages.last?.sharedDrawing==drawingStore.current.messages.last?.sharedDrawing,"rounds, ink, authors and completion survive relaunch")
 drawingStore.state.mode="friends"
 check(!drawingStore.submitDrawingRound(drawingID,drawing:ink,note:"wrong space",revision:2),"cross-space submissions rejected")
 check(!drawingStore.finishSharedDrawing(drawingID,revision:2),"cross-space completion rejected")
 let groupID=drawingStore.startSharedDrawing()
 check(drawingStore.current.messages.last?.sharedDrawing?.players==drawingStore.memberNames && drawingStore.memberNames.count==6,"friend group participants captured")
 check(drawingStore.submitDrawingRound(groupID,drawing:ink,note:"group",revision:0),"group first turn works")
 check(drawingStore.state.couple.messages.last?.sharedDrawing==roundTrip.couple.messages.last?.sharedDrawing,"group changes do not alter couple work")
 check(!drawingStore.submitDrawingRound(UUID(),drawing:ink,note:"missing",revision:0),"unknown invitation rejected")
 var bounds=SharedDrawingSession(players:["A","B"])
 check(bounds.append(drawing:Data(repeating:1,count:131072),note:String(repeating:"猫",count:90),revision:0),"maximum round data accepted")
 check(bounds.rounds[0].note.count==80,"notes capped by characters")
 check(!bounds.append(drawing:Data(repeating:1,count:131073),note:"oversize",revision:1),"oversize contribution rejected")
 var limited=SharedDrawingSession(players:["A","B"])
 for i in 0..<24 { check(limited.append(drawing:ink,note:"",revision:i),"round within limit accepted") }
 check(!limited.append(drawing:ink,note:"extra",revision:24),"round limit enforced")
 check(limited.finish(revision:24),"capped drawing can still finish")
 var noPlayers=SharedDrawingSession(players:[])
 check(!noPlayers.append(drawing:ink,note:"",revision:0),"missing players rejected")
 var duplicatePlayers=SharedDrawingSession(players:["A","A"])
 check(!duplicatePlayers.append(drawing:ink,note:"",revision:0),"duplicate identities rejected")
 var onePlayer=SharedDrawingSession(players:["A"])
 check(!onePlayer.append(drawing:ink,note:"",revision:0),"one player rejected")
 var tooManyPlayers=SharedDrawingSession(players:(1...9).map{String($0)})
 check(!tooManyPlayers.append(drawing:ink,note:"",revision:0),"group size limit enforced")
 var blankPlayer=SharedDrawingSession(players:["A"," "])
 check(!blankPlayer.append(drawing:ink,note:"",revision:0),"blank identity rejected")
 print(String(data:try JSONSerialization.data(withJSONObject:["checks":checks,"failures":0,"scope":"Production growth, AI, invitation and shared drawing rules with in-memory store adapter"]),encoding:.utf8)!)
 }
}
'''.replace('\\.','\.').replace('\\"','\"').replace('\\(checks)','\(checks)')
(root/'tmp').mkdir(exist_ok=True)
networking = '\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n'
path=root/'tmp/GrowthRuleChecks.swift';path.write_text(networking+models+creative+play+growth+store+service+choice+shared+tests)
run_checks(path)
