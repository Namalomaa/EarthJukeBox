// Pure, deterministic NASA -> music mapping. No audio/DOM dependencies.
// Each melody event includes the exact source flash that produces it.
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const scale=[60,62,64,67,69,72,74,76,79,81]; // C-major pentatonic
const chords=[[48,52,55],[45,48,52],[41,45,48],[43,47,50]];
const roots=[36,33,29,31];
export const midiHz=m=>440*2**((m-69)/12);
export function buildMapScore(input){
  const flashes=input.filter(f=>Number.isFinite(Date.parse(f.time)) && Number.isFinite(+f.latitude) && Number.isFinite(+f.longitude) && Number.isFinite(+f.radiance))
    .map(f=>({time:f.time, ms:Date.parse(f.time),latitude:+f.latitude,longitude:+f.longitude,radiance:+f.radiance}))
    .sort((a,b)=>a.ms-b.ms);
  if(!flashes.length)throw new Error('No valid NASA flashes in lightning.json');
  const bars=15, barSeconds=2, totalSeconds=bars*barSeconds;
  const first=flashes[0].ms, last=flashes.at(-1).ms, span=Math.max(1,last-first+1);
  const groups=Array.from({length:bars},()=>[]);
  for(const f of flashes) groups[clamp(Math.floor((f.ms-first)/span*bars),0,bars-1)].push(f);
  const counts=groups.map(g=>g.length), sortedCounts=[...counts].sort((a,b)=>a-b), q=i=>sortedCounts[Math.floor((sortedCounts.length-1)*i)];
  const lo=q(.15),hi=q(.85);const events=[],sections=[];
  groups.forEach((group,i)=>{
    const start=i*barSeconds,end=start+barSeconds;
    const activity=clamp((group.length-lo)/Math.max(1,hi-lo),0,1);
    const startDate=new Date(first+(i/bars)*span).toISOString();
    const endDate=new Date(i===bars-1?last:first+((i+1)/bars)*span).toISOString();
    const sampled=group.filter((_,j)=>j%Math.max(1,Math.ceil(group.length/230))===0).slice(0,230);
    const section={index:i,start,end,startDate,endDate,count:group.length,activity,dots:sampled};
    sections.push(section);
    // Fixed musical scaffold is disclosed: makes music harmonious, is not a NASA measurement.
    for(const note of chords[i%4])events.push({track:'pad',at:start,duration:1.85,note,velocity:.23+activity*.13});
    events.push({track:'bass',at:start,duration:.85,note:roots[i%4],velocity:.48+activity*.12});
    events.push({track:'bass',at:start+1,duration:.55,note:roots[i%4]+7,velocity:.31+activity*.12});
    events.push({track:'kick',at:start,duration:.12,velocity:.40+activity*.12});
    events.push({track:'kick',at:start+1,duration:.12,velocity:.29+activity*.10});
    const numHats=2+Math.round(activity*4);
    for(let h=0;h<numHats;h++)events.push({track:'hat',at:start+.23+h*(1.48/numHats),duration:.05,velocity:.10+activity*.08});
    const melodicCount=group.length ? 3+Math.round(activity*5) : 0;
    for(let j=0;j<melodicCount;j++){
      const flash=group[Math.min(group.length-1,Math.floor((j+.5)*group.length/melodicCount))];
      // Latitude -> C pentatonic note; radiance -> velocity; flash count -> notes per section.
      const ix=clamp(Math.floor((flash.latitude+90)/180*scale.length),0,scale.length-1);
      const note=scale[ix], at=start+(j+.45)*1.75/melodicCount;
      const velocity=clamp(.22+Math.log1p(Math.max(0,flash.radiance))/28+activity*.10,.25,.83);
      events.push({track:'melody',at,duration:.20+(j%3===0?.17:0),note,velocity,flash,section:i});
    }
  });
  events.sort((a,b)=>a.at-b.at);
  return {events,sections,totalSeconds,first:new Date(first).toISOString(),last:new Date(last).toISOString(),flashCount:flashes.length};
}
