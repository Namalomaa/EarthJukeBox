// Tone.js playback adapter. Saba can swap instruments, effects, scheduling here.
export function createMusicEngine(Tone){
  const melody=new Tone.PolySynth(Tone.Synth,{
    oscillator:{type:'triangle'}, envelope:{attack:.018,decay:.16,sustain:.20,release:.4}
  }).connect(new Tone.Volume(-5).toDestination());
  const pad=new Tone.PolySynth(Tone.Synth,{
    oscillator:{type:'sine'}, envelope:{attack:.18,decay:.35,sustain:.55,release:.95}
  }).connect(new Tone.Volume(-10).toDestination());
  const bass=new Tone.PolySynth(Tone.Synth,{
    oscillator:{type:'triangle'}, envelope:{attack:.01,decay:.24,sustain:.32,release:.24}
  }).connect(new Tone.Volume(-9).toDestination());
  const kick=new Tone.MembraneSynth({pitchDecay:.05,octaves:4,envelope:{attack:.001,decay:.22,sustain:0}})
    .connect(new Tone.Volume(-15).toDestination());
  const hat=new Tone.NoiseSynth({noise:{type:'pink'},envelope:{attack:.001,decay:.045,sustain:0}})
    .connect(new Tone.Volume(-25).toDestination());
  const instruments={melody,pad,bass,kick,hat};
  let score=null,position=0,startedAt=0,playing=false,raf=null,finishTimer=null;
  let onTick=()=>{},onFinish=()=>{};
  function cancel(){Tone.Transport.cancel(0);clearTimeout(finishTimer);cancelAnimationFrame(raf);}
  function tick(){if(!playing)return;position=Math.min(score.totalSeconds,(Tone.now()-startedAt));onTick(position);raf=requestAnimationFrame(tick);}
  function stop(){playing=false;cancel();Tone.Transport.stop();position=0;onTick(0);}
  async function play(nextScore,opts={}){
    if(nextScore)score=nextScore;if(!score)throw Error('Build a score first');
    onTick=opts.onTick||onTick;onFinish=opts.onFinish||onFinish;
    await Tone.start();
    if(playing)stop();
    // Restart from beginning: avoids Transport seeking ambiguity across Tone versions.
    position=0;Tone.Transport.stop();Tone.Transport.cancel(0);Tone.Transport.position=0;
    Tone.Transport.bpm.value=score.bpm;
    for(const event of score.events){
      Tone.Transport.schedule(time=>{
        const synth=instruments[event.track];if(!synth)return;
        if(event.track==='kick')synth.triggerAttackRelease('C2',event.duration,time,event.velocity);
        else if(event.track==='hat')synth.triggerAttackRelease(event.duration,time,event.velocity);
        else synth.triggerAttackRelease(Tone.Frequency(event.note,'midi'),event.duration,time,event.velocity);
      },event.at);
    }
    startedAt=Tone.now()+.08;playing=true;
    Tone.Transport.start('+0.08');tick();
    finishTimer=setTimeout(()=>{stop();onFinish();},(score.totalSeconds+.12)*1000);
  }
  function dispose(){stop();Object.values(instruments).forEach(s=>s.dispose());}
  return {play,stop,dispose,get playing(){return playing;}};
}
