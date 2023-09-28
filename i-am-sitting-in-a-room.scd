s.options.device_("Scarlett 2i4 USB");

(
Window.closeAll;
fork({
	~maxDur = 120;
	~fadeDur = 3;

	~bufs = {Buffer.alloc(s,s.sampleRate * ~maxDur)} ! 2;

	~playAndRec = {
		arg i, dur;
		{
			arg gate = 1;
			var out;
			var env = EnvGen.kr(Env([0,1,1,0],[~fadeDur,dur - (~fadeDur*2),~fadeDur]),gate,doneAction:2);

			RecordBuf.ar(SoundIn.ar(0) * env,~bufs[(i+1)%2],0,1,0,1,0,1,2);

			out = PlayBuf.ar(1,~bufs[i],BufRateScale.ir(~bufs[i]),1,0,0,2);

			out.dup;
		}.play;
	};

	s.sync;

	~win = Window.centered("I am sitting in a room...",400,400);

	~win.layout = HLayout(
		Button(nil,Rect(500,500,300,100))
		.states_([
			["Start First Take"],
			["End First Take"]
		])
		.action_({
			arg b;
			if(b.value.asBoolean){
				~synth = ~playAndRec.(1,~maxDur);
				~start = thisProcess.tick;
			}{
				fork{
					~realDur = thisProcess.tick - ~start;
					~synth.set(\gate,0);

					0.5.wait;
					~bufs.do(_.normalize);
					0.5.wait;

					inf.do{
						arg i;
						~synth = ~playAndRec.(i%2,~realDur);
						(~realDur + 0.5).wait;
						~bufs.do(_.normalize);
						0.5.wait;
					}
				}
			}
		})
	);

	~win.front;
},AppClock);
);
