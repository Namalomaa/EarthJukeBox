// NASA flash observations -> deterministic, tonal musical score.
// Pure JavaScript: no Tone.js dependency. Rawaa can iterate here independently.
const clamp=(v,min,max)=>Math.max(min,Math.min(max,v));
const midiToFrequency=m=>440*Math.pow(2,(m-69)/12);
const quantile=(sorted,q)=>sorted.length?sorted[Math.floor((sorted.length-1)*q)]:0;
export function buildMusicalScore(flashes,options={}) {
  if (!Array.isArray(flashes)||flashes.length===0) throw Error('No NASA flashes found');
  const bpm=120, bars=15, secondsPerBeat=60/bpm, beatsPerBar=4;
  const totalSeconds=bars*beatsPerBar*secondsPerBeat; // 30 sec
  const sorted=flashes.map(f=>({...f,ms:Date.parse(f.time)}))
    .filter(f=>Number.isFinite(f.ms)&&Number.isFinite(+f.latitude)&&Number.isFinite(+f.longitude))
    .sort((a,b)=>a.ms-b.ms);
  if(!sorted.length) throw Error('No valid flash timestamps');
  const start=sorted[0].ms,end=sorted[sorted.length-1].ms+1,span=end-start;
  const groups=Array.from({length:bars},()=>[]);
  for(const f of sorted) groups[clamp(Math.floor((f.ms-start)/span*bars),0,bars-1)].push(f);
  const counts=groups.map(g=>g.length);
  const low=quantile([...counts].sort((a,b)=>a-b),.15);
  const high=quantile([...counts].sort((a,b)=>a-b),.85);
  // Chord roots: C, A minor, F, G; fixed harmonic grammar for musical coherence.
  const chords=[[48,52,55],[45,48,52],[41,45,48],[43,47,50]];
  const roots=[36,33,29,31];
  // C-major pentatonic (scale degrees), with octave range determined by latitude.
  const scale=[60,62,64,67,69,72,74,76,79,81];
  const events=[],segments=[];
  groups.forEach((group,i)=>{
    const t=i*beatsPerBar*secondsPerBeat;
    const energy=clamp((group.length-low)/Math.max(1,high-low),0,1);
    const chord=chords[i%4];
    const stats=group.length?{
      meanLatitude:group.reduce((v,f)=>v+Number(f.latitude),0)/group.length,
      meanLongitude:group.reduce((v,f)=>v+Number(f.longitude),0)/group.length,
      medianRadiance:quantile(group.map(f=>Number(f.radiance)||0).sort((a,b)=>a-b),.5)
    }:{meanLatitude:0,meanLongitude:0,medianRadiance:0};
    segments.push({index:i,start:t,end:t+2,count:group.length,energy,
      date:new Date(start+i*span/bars).toISOString(),sample:group.filter((_,j)=>j%Math.max(1,Math.ceil(group.length/80))===0).slice(0,80),...stats});
    // Pad: a full harmonious chord every bar, independent of activity to maintain a musical foundation.
    for(const midi of chord) events.push({track:'pad',at:t,duration:1.83,note:midi,velocity:.36+energy*.14,pan:0});
    // Bass: fundamental and fifth; activity makes the second strike stronger.
    events.push({track:'bass',at:t,duration:.82,note:roots[i%4],velocity:.62,pan:0});
    events.push({track:'bass',at:t+1,duration:.58,note:roots[i%4]+7,velocity:.33+energy*.22,pan:0});
    // Stable 8th-note rhythmic grid; activity controls number of actual strikes.
    const n=group.length?3+Math.round(energy*5):0;
    for(let k=0;k<n;k++){
      const flash=group[Math.min(group.length-1,Math.floor((k+.5)*group.length/n))];
      const latitude=Number(flash.latitude);
      const longitude=Number(flash.longitude);
      const radiance=Math.max(0,Number(flash.radiance)||0);
      const melodicIndex=clamp(Math.floor((latitude+90)/180*scale.length),0,scale.length-1);
      const jump=(i+k)%3===0?1:0;
      const midi=scale[clamp(melodicIndex+jump,0,scale.length-1)];
      const slot=Math.floor(k*8/n);
      const at=t+slot*.25;
      const vel=clamp(.4+Math.log1p(radiance)/40+.16*energy,.4,.88);
      events.push({track:'melody',at,duration:k%3===0?.38:.19,note:midi,velocity:vel,pan:clamp(longitude/180,-.72,.72)});
    }
    // Percussion is quiet and consistent. Extra high-hats depend on lightning density.
    events.push({track:'kick',at:t,duration:.12,note:36,velocity:.44+energy*.13,pan:0});
    events.push({track:'kick',at:t+1,duration:.12,note:36,velocity:.3+energy*.12,pan:0});
    for(let k=0;k<2+Math.round(energy*4);k++)events.push({track:'hat',at:t+.25+k*.25,duration:.04,note:78,velocity:.15+energy*.08,pan:0});
  });
  return {bpm,bars,totalSeconds,events,segments,sourceStart:new Date(start).toISOString(),sourceEnd:new Date(end-1).toISOString(),totalFlashes:sorted.length};
}
export {midiToFrequency};
