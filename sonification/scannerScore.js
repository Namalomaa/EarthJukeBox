// ISS LIS V3 spatial scanner score. Deterministic scientific mapping.
// Scanner order is longitude (west -> east), not chronological flash time.
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const scale=[48,50,52,55,57,60,62,64,67,69,72,74,76,79,81];
export const noteHz=n=>440*2**((n-69)/12);
export function buildDayIndex(input){
  const source=Array.isArray(input)?input:input.flashes;
  if(!Array.isArray(source))throw Error('Missing flashes array');
  const grouped=new Map();
  for(const f of source){
    if(typeof f.time!=='string'||!Number.isFinite(Date.parse(f.time))||![f.latitude,f.longitude,f.radiance].every(v=>Number.isFinite(Number(v))))continue;
    let key=f.time.slice(0,10);
    if(!grouped.has(key))grouped.set(key,[]);
    grouped.get(key).push({time:f.time,latitude:+f.latitude,longitude:+f.longitude,radiance:+f.radiance});
  }
  for(const group of grouped.values())group.sort((a,b)=>a.longitude-b.longitude||a.time.localeCompare(b.time));
  const first=source.length?source.reduce((a,b)=>a.time<b.time?a:b).time.slice(0,10):'2017-03-01';
  const last=source.length?source.reduce((a,b)=>a.time>b.time?a:b).time.slice(0,10):'2017-03-12';
  const days=[];
  for(let d=new Date(first+'T00:00:00Z'),end=new Date(last+'T00:00:00Z');d<=end;d.setUTCDate(d.getUTCDate()+1)){
    const day=d.toISOString().slice(0,10);
    days.push({day,flashes:grouped.get(day)||[]});
  }
  return days;
}
export function buildScannerScore(day,seconds=24,columns=48){
  const flashes=day.flashes;
  const byColumn=Array.from({length:columns},()=>[]);
  for(const f of flashes){byColumn[clamp(Math.floor((f.longitude+180)/360*columns),0,columns-1)].push(f)}
  const maxCount=Math.max(1,...byColumn.map(a=>a.length));
  const events=[];
  // Music is spatially organized; each longitude strip plays at the same visual scanner position.
  byColumn.forEach((group,i)=>{
    if(!group.length)return;
    const density=group.length/maxCount;
    const voices=Math.min(5,1+Math.floor(Math.log2(group.length+1)));
    const sorted=[...group].sort((a,b)=>b.radiance-a.radiance);
    for(let j=0;j<voices;j++){
      // Spread sampling across flashes sorted by radiance to avoid duplicates.
      const f=sorted[Math.min(sorted.length-1,Math.floor((j+.5)*sorted.length/voices))];
      const pitchIndex=clamp(Math.floor((f.latitude+90)/180*scale.length),0,scale.length-1);
      const velocity=clamp(.20+Math.log1p(Math.max(0,f.radiance))/38+density*.13,.22,.78);
      events.push({at:i*seconds/columns+j*.045,duration:.20+.14*density,note:scale[pitchIndex],velocity,flash:f,column:i,sectionCount:group.length});
    }
  });
  return {events,byColumn,seconds,columns,day:day.day,count:flashes.length};
}
