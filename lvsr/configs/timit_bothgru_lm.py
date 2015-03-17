Config(
    net=Config(dec_transition='GatedRecurrent',
               enc_transition='GatedRecurrent',
               use_states_for_readout=True),
    initialization=[
        ("/recognizer", "rec_weights_init", "IsotropicGaussian(0.1)")],
    data=Config(normalization="norm.pkl"))