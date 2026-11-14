// Tone.js adapter: one transport owns timing for sound AND map.
export function createMapAudioEngine(Tone){
  const bus=new Tone.Gain(.78).toDestination();
  const melodic=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'triangle'},envelope:{attack:.015,decay:.16,sustain:.2,release:.24}}).connect(new Tone.Gain(.60).connect(bus));
  const pad=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'sine'},envelope:{attack:.18,decay:.35,sustain:.45,release:.55}}).connect(new Tone.Gain(.19).connect(bus));
  const bass=new Tone.PolySynth(Tone.Synth,{oscillator:{type:'triangle'},envelope:{attack:.01,decay:.19,sustain:.27,release:.22}}).connect(new Tone.Gain(.28).connect(bus));
  const kick=new Tone.MembraneSynth({pitchDecay:.045,octaves:3,envelope:{attack:.001,decay:.16,sustain:0}}).connect(new Tone.Gain(.19).connect(bus));
  const hat=new Tone.NoiseSynth({noise:{type:'pink'},envelope:{attack:.001,decay:.04,sustain:0}}).connect(new Tone.Gain(.065).connect(bus));
  let score=null, running=false, frame=0, onTick=()=>{},onDone=()=>{},onMelody=()=>{};
  function paint(){if(!running)return;const t=Math.min(score.totalSeconds,Tone.Transport.seconds);onTick(t);if(t>=score.totalSeconds-.02){stop();onDone();return;}frame=requestAnimationFrame(paint);}
  function silence(){[melodic,pad,bass].forEach(s=>s.releaseAll());}
  function stop(){running=false;cancelAnimationFrame(frame);Tone.Transport.stop();Tone.Transport.cancel(0);Tone.Transport.position=0;silence();onTick(0);}
  async function play(nextScore,handlers={}){
    await Tone.start();stop();score=nextScore;
    onTick=handlers.onTick||(()=>{});onDone=handlers.onDone||(()=>{});onMelody=handlers.onMelody||(()=>{});
    Tone.Transport.bpm.value=120;
    for(const e of score.events){Tone.Transport.schedule((audioTime)=>{
      if(!running)return;
      if(e.track==='melody'){melodic.triggerAttackRelease(Tone.Frequency(e.note,'midi'),e.duration,audioTime,e.velocity); // UI callback on animation frame, not audio thread
        requestAnimationFrame(()=>{if(running)onMelody(e);});
      }else if(e.track==='pad')pad.triggerAttackRelease(Tone.Frequency(e.note,'midi'),e.duration,audioTime,e.velocity);
      else if(e.track==='bass')bass.triggerAttackRelease(Tone.Frequency(e.note,'midi'),e.duration,audioTime,e.velocity);
      else if(e.track==='kick')kick.triggerAttackRelease('C2',e.duration,audioTime,e.velocity);
      else if(e.track==='hat')hat.triggerAttackRelease(e.duration,audioTime,e.velocity);
    },e.at);}
    Tone.Transport.scheduleOnce(()=>{requestAnimationFrame(()=>{if(running){stop();onDone();}});},score.totalSeconds);
    running=true;Tone.Transport.start('+0.10');paint();
  }
  return {play,stop,get playing(){return running;}};
}
