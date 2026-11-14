// Tone.js audio renderer; scanner motion and note triggers share Transport time.
export function createScannerAudio(Tone){
 const main=new Tone.Gain(.8).toDestination();
 const lead=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'triangle'},envelope:{attack:.015,decay:.16,sustain:.24,release:.26}}).connect(new Tone.Gain(.66).connect(main));
 const pad=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'sine'},envelope:{attack:.18,decay:.35,sustain:.4,release:.5}}).connect(new Tone.Gain(.18).connect(main));
 const low=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'triangle'},envelope:{attack:.02,decay:.18,sustain:.2,release:.3}}).connect(new Tone.Gain(.17).connect(main));
 let running=false,raf=0, score=null,handlers={};
 const safeCall=(name,...args)=>{if(typeof handlers[name]==='function')handlers[name](...args)};
 function stop(){running=false;cancelAnimationFrame(raf);Tone.Transport.stop();Tone.Transport.cancel(0);Tone.Transport.position=0;lead.releaseAll();pad.releaseAll();low.releaseAll();}
 function paint(){if(!running)return;const t=Math.min(score.seconds,Tone.Transport.seconds);safeCall('onTick',t);if(t>=score.seconds-.03){stop();safeCall('onEnd');return}raf=requestAnimationFrame(paint)}
 async function play(next,callbacks={}){
   await Tone.start();stop();score=next;handlers=callbacks;
   // A constant harmonic scaffold makes the composition pleasant. It is not a measured NASA variable.
   const harmony=[[48,52,55],[45,48,52],[41,45,48],[43,47,50]];
   const roots=[36,33,29,31];
   for(let block=0;block<Math.ceil(score.seconds/4);block++){
     const at=block*4, idx=block%4;
     Tone.Transport.schedule((t)=>{if(running){harmony[idx].forEach(n=>pad.triggerAttackRelease(Tone.Frequency(n,'midi'),3.5,t,.18));low.triggerAttackRelease(Tone.Frequency(roots[idx],'midi'),1.4,t,.24)}},at);
   }
   for(const e of score.events){Tone.Transport.schedule((t)=>{
     if(!running)return;
     lead.triggerAttackRelease(Tone.Frequency(e.note,'midi'),e.duration,t,e.velocity);
     requestAnimationFrame(()=>{if(running)safeCall('onNote',e)});
   },e.at)}
   Tone.Transport.scheduleOnce(()=>requestAnimationFrame(()=>{if(running){stop();safeCall('onEnd')}}),score.seconds);
   running=true;Tone.Transport.start('+0.1');paint();
 }
 return {play,stop,get playing(){return running}};
}
