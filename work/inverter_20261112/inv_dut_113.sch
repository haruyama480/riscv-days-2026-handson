v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N -40 -50 -40 -10 {lab=VDD}
N -40 50 -40 110 {lab=Q}
N -40 80 60 80 {lab=Q}
N -120 80 -100 80 {lab=A}
N -100 20 -80 20 {lab=A}
N -100 20 -100 140 {lab=A}
N -100 140 -80 140 {lab=A}
N -40 20 -10 20 {lab=VDD}
N -10 -30 -10 20 {lab=VDD}
N -40 -30 -10 -30 {lab=VDD}
N -40 170 -40 210 {lab=VSS}
N -40 140 -10 140 {lab=VSS}
N -10 140 -10 190 {lab=VSS}
N -40 190 -10 190 {lab=VSS}
C {symbols/nfet_03v3.sym} -60 140 0 0 {name=M2
L=0.30u
W=1.80u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_03v3
spiceprefix=X
}
C {ipin.sym} -120 80 0 0 {name=p1 lab=A}
C {opin.sym} 60 80 0 0 {name=p2 lab=Q}
C {symbols/pfet_03v3.sym} -60 20 0 0 {name=M1
L=0.3u
W=1.8u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_03v3
spiceprefix=X
}
C {iopin.sym} -40 210 0 0 {name=p3 lab=VSS}
C {iopin.sym} -40 -50 0 0 {name=p4 lab=VDD}
