// Pure data-to-score mapping; no audio dependencies. Additive file: Rawaa can refine it.
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const n=(f,k)=>Number(f[k]);
const iso=t=>new Date(t).toISOString();
export function buildSyncedScore(flashes, labels, opts={}) {
  const fps=60, startFrame=0, endFrame=465, playbackRate=.25;
  const bars=15, totalSeconds=(endFrame-startFrame)/fps/playbackRate;
  if(!Array.isArray(labels)||labels.length<endFrame+1)throw Error('Not enough NASA labels');
  const timeAtFrame=frame=>labels[clamp(Math.round(frame),0,labels.length-1)].ms;
  const start=timeAtFrame(startFrame), end=timeAtFrame(endFrame);
  if(!(end>start))throw Error('Unexpected label ordering');
  const observation=flashes.map(f=>({...f,ms:Date.parse(f.time)}))
    .filter(f=>Number.isFinite(f.ms)&&Number.isFinite(n(f,'latitude'))&&Number.isFinite(n(f,'longitude')))
    .sort((a,b)=>a.ms-b.ms);
  const segs=[];const events=[];
  const pent=[60,62,64,67,69,72,74,76,79,81];
  const chords=[[48,52,55],[45,48,52],[41,45,48],[43,47,50]];
  const roots=[36,33,29,31];
  const barsData=[];
  for(let i=0;i<bars;i++){
    const fa=startFrame+(endFrame-startFrame)*i/bars;
    const fb=startFrame+(endFrame-startFrame)*(i+1)/bars;
    const t0=timeAtFrame(fa),t1=timeAtFrame(fb);
    const group=observation.filter(f=>f.ms>=t0&&f.ms<t1);
    barsData.push({i,fa,fb,t0,t1,group});
  }
  const counts=barsData.map(b=>b.group.length);
  const min=Math.min(...counts),max=Math.max(...counts);
  const dur=totalSeconds/bars;
  for(const {i,fa,fb,t0,t1,group} of barsData){
    const at=i*dur;
    const energy=clamp(Math.log1p(group.length-min)/Math.max(.01,Math.log1p(max-min)),0,1);
    const selected=group.filter((_,j)=>j%Math.max(1,Math.ceil(group.length/85))===0).slice(0,85);
    segs.push({index:i,start:at,end:at+dur,videoStart:fa/fps,videoEnd:fb/fps,
      dateStart:iso(t0),dateEnd:iso(t1),count:group.length,energy,sample:selected});
    // The harmony is deliberately fixed: scientifically driven melodic notes are tagged with source observations.
    for(const note of chords[i%4])events.push({track:'pad',at,duration:dur*.87,note,velocity:.26+energy*.13,source:'harmonic scaffold'});
    events.push({track:'bass',at,duration:dur*.42,note:roots[i%4],velocity:.42+energy*.18,source:'harmonic scaffold'});
    if(group.length){
      const hits=2+Math.round(energy*6);
      for(let k=0;k<hits;k++){
        const flash=group[Math.min(group.length-1,Math.floor((k+.5)*group.length/hits))];
        const latitude=n(flash,'latitude'), longitude=n(flash,'longitude'),radiance=Math.max(0,n(flash,'radiance')||0);
        const pitchIndex=clamp(Math.floor((latitude+90)/180*pent.length),0,pent.length-1);
        events.push({track:'melody',at:at+(k+.2)*dur/(hits+.2),duration:.17+energy*.12,
          note:pent[pitchIndex],velocity:clamp(.38+Math.log1p(radiance)/45+energy*.12,.38,.86),
          pan:clamp(longitude/180,-.75,.75),source:'NASA flash',
          flash:{time:flash.time,latitude,longitude,radiance}});
      }
    }
    events.push({track:'kick',at,duration:.12,note:36,velocity:.30+energy*.15,source:'rhythmic scaffold'});
    for(let k=0;k<2+Math.round(energy*3);k++)events.push({track:'hat',at:at+.2+k*dur/7,duration:.035,note:78,velocity:.1+energy*.1,source:'density-driven percussion'});
  }
  events.sort((a,b)=>a.at-b.at);
  const selectedFlashes=barsData.reduce((s,b)=>s+b.group.length,0);
  return {startFrame,endFrame,playbackRate,totalSeconds,bars,segments:segs,events,selectedFlashes,
    scientificStart:iso(start),scientificEnd:iso(end),mapping:'timestamp-matched flash groups, NOT the video rolling ten-day count'};
}
export function parseNasaLabels(text){
  const lines=text.split(/\r?\n/).map(s=>s.trim()).filter(Boolean);
  const months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const result=[];
  for(const line of lines){
    const m=line.match(/^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})$/);
    if(!m)throw Error('Unexpected label: '+line);
    let year=Number(m[3]);if(year===2003)year=2023; // known anomalous labels, provisional only
    const mo=months.indexOf(m[2]);if(mo<0)throw Error('Unexpected month in label '+line);
    const ms=Date.UTC(year,mo,Number(m[1]),Number(m[4]),Number(m[5]));
    result.push({original:line,ms});
  }
  return result;
}
