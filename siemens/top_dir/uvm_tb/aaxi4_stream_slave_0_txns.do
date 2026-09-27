onerror resume
wave update off
wave tags  F0
wave spacer -group Transaction -backgroundcolor Salmon {AAXI4_STREAM_SLAVE_0 Txns}
wave group Transaction -backgroundcolor #004466
wave insertion [expr [wave index insertpoint] + 1]
wave update on
WaveSetStreamView
