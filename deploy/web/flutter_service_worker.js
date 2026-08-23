'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "eb1b6e641957c66d362f816854cf31b5",
"assets/AssetManifest.bin.json": "253c837fb0a98e4c2efc0e1a3ed28d6b",
"assets/AssetManifest.json": "a0cef392482028e192afe93f689cd0ea",
"assets/assets/branding/app_icon.ico": "da8b7825031c07af9b4fd61e358e661e",
"assets/assets/branding/paes_med_ai_icon_source.png": "ee807d599501fef75e6e612138ef00f8",
"assets/assets/branding/paes_med_ai_logo_bg.png": "aa2542e81a0dda962a22f70b3852a031",
"assets/data/materiais/imagens/bi_bota_capa.png": "5baad0c8881cc6a873c24b550db79e1f",
"assets/data/materiais/imagens/bi_cito_capa.png": "19f327e202d45ae9ff4dc310cad68e35",
"assets/data/materiais/imagens/bi_eco_capa.jpg": "fc6ec9fcf850479b1232a88aa5530f38",
"assets/data/materiais/imagens/bi_embrio_capa.png": "332cf445bad97ef8e648cf243e3579aa",
"assets/data/materiais/imagens/bi_evo_capa.png": "22c0b1ee65949afde2e5900aeae3a0f1",
"assets/data/materiais/imagens/bi_gene_capa.jpg": "25d8b16a7651c1611893b9f1511c8307",
"assets/data/materiais/imagens/bi_histo_capa.jpg": "790f4794b68e1d3caa93b93001c5efbe",
"assets/data/materiais/imagens/bi_intro_capa.jpg": "a53e11e2857d46171bd440fd3ea1d91d",
"assets/data/materiais/imagens/bi_metab_capa.png": "a55523bd2282b21af0df4573baf67969",
"assets/data/materiais/imagens/bi_micro_capa.jpg": "ba0f52eee28e96e9a9532557969ea20d",
"assets/data/materiais/imagens/bi_saude_capa.jpg": "3dd403fa1c411f4d6af97c97464558c5",
"assets/data/materiais/imagens/bi_taxo_capa.jpg": "2ea38bb39ebcea269047a24c2d48492f",
"assets/data/materiais/imagens/bi_zoo_capa.jpg": "b6e563dc10f7fd72238083c492bcb8f9",
"assets/data/materiais/imagens/br_ano_alteracoes1.jpg": "e4373b8bfa65cec83e12a3625ed91e90",
"assets/data/materiais/imagens/br_ano_alteracoes2.jpg": "37c0f29cc27f2a8e2a0bd99e45d1c2bd",
"assets/data/materiais/imagens/br_ano_alteracoes3.jpg": "7b04155c01112f875a92b22ea84fa8fd",
"assets/data/materiais/imagens/br_ano_cariotipo_be.jpg": "810eb8dff8d24bbde76fbcdcdc1fb4b1",
"assets/data/materiais/imagens/br_ano_cariotipo_down.jpg": "fafc4de49884390fcdb1626f08348b88",
"assets/data/materiais/imagens/br_ano_cariotipo_normal.jpg": "ec35f77b3e8e942b95cc5db63f230e99",
"assets/data/materiais/imagens/br_ano_down_tm.jpg": "ddb348ff1c08a7f79a1bf8f832e7b9fc",
"assets/data/materiais/imagens/br_ano_idiograma.jpg": "a071bdb443567a49e7a29ec311a6601b",
"assets/data/materiais/imagens/br_ano_klinefelter.jpg": "22d446df90edf36114a70206ee0fde9a",
"assets/data/materiais/imagens/br_ano_klinefelter_me.jpg": "c5252dcf618bed14fdfbccb112e7234c",
"assets/data/materiais/imagens/br_ano_patau.jpg": "478877f077eb96777a4e689df28f5b1a",
"assets/data/materiais/imagens/br_ano_turner_cariotipo.jpg": "9a6e5d0872c2ba5049f69f33ca50ed7c",
"assets/data/materiais/imagens/br_ano_turner_ie.jpg": "b227bc6ef449a7f70f5f092994b88e29",
"assets/data/materiais/imagens/br_ano_turner_ilust.jpg": "3eac526b944b03e3b7aa10a6308d69e8",
"assets/data/materiais/imagens/br_bot_angiospermas.jpg": "0753d25b6646b98f07559c2ef91ca0d2",
"assets/data/materiais/imagens/br_bot_briofitas.jpg": "7b376836c871ff058b439fdc1ec695d5",
"assets/data/materiais/imagens/br_bot_flor.jpg": "10b868b3392f231895840cbbe997ce07",
"assets/data/materiais/imagens/br_bot_gimnospermas.jpg": "0fbd7957f05653a69ba283a869bf5996",
"assets/data/materiais/imagens/br_bot_monocots.jpg": "b82150c114cf784f3f71041857b194da",
"assets/data/materiais/imagens/br_bot_pteridofitas.jpg": "cd8c5fed327644cbd67df37de3f869e8",
"assets/data/materiais/imagens/br_bot_semente.jpg": "9bb311d52d63e975e42329e635754c4e",
"assets/data/materiais/imagens/br_bot_tecidos.jpg": "4c9775f24e383004a5838e00e71db28a",
"assets/data/materiais/imagens/br_brasilescla_extra.jpg": "74376b3bb735acd4f5befb86dfb2a273",
"assets/data/materiais/imagens/br_brasilescola_antiga.jpg": "d4527569c791bf16b262a447a1b3e68c",
"assets/data/materiais/imagens/br_brasilescola_estrutura.jpg": "aa94b8f5f3aeeee399f879425d1624cb",
"assets/data/materiais/imagens/br_brasilescola_membrana2.jpg": "33da7f68dff4f4e7ce796e50d2d12173",
"assets/data/materiais/imagens/br_brasilescola_transporte.jpg": "feb78e9296f557d179b4363776d8cdc4",
"assets/data/materiais/imagens/br_ciclo_celular_be.jpg": "544f968cc23bdfa43746f532554e66a1",
"assets/data/materiais/imagens/br_ciclo_interfase_mitose.jpg": "1f53229c613c428522f9eaee6c168ae9",
"assets/data/materiais/imagens/br_cito_anatomia_celula.jpg": "46b77df8a98408a372b4de895a140622",
"assets/data/materiais/imagens/br_cito_celula_eucarionte.jpg": "04aed0cb413412b52f170315ffca3cf6",
"assets/data/materiais/imagens/br_cito_celula_vegetal.jpg": "ae9b5ee4a6e4a1a6ec42015a9a57d132",
"assets/data/materiais/imagens/br_cito_citoesqueleto_be.jpg": "126d3e98513aba40b0e2cba0e514fa36",
"assets/data/materiais/imagens/br_cito_citoesqueleto_ie.jpg": "d1d78ee7dd42eb2c2d44f771ce8ae142",
"assets/data/materiais/imagens/br_cito_citoesqueleto_tm.jpg": "7b39f0538dfe91179c0e4e79ca8e6b5a",
"assets/data/materiais/imagens/br_cito_eucariotica.jpg": "833c9074b0d5120c286c97cbc5dac2e9",
"assets/data/materiais/imagens/br_cito_microtubulos.jpg": "3064c273a9e0dbd7157b64398d1cb5b9",
"assets/data/materiais/imagens/br_cls_animalia.jpg": "c064f11aa59408c632b880396cb6f0c9",
"assets/data/materiais/imagens/br_cls_artr%25C3%25B3podes.jpg": "b2b31c7ac4f4bb602b1d5fe6270aa6a1",
"assets/data/materiais/imagens/br_cls_arvore.jpg": "9f25f5c242cefd7ed7e4b49e927f3d0f",
"assets/data/materiais/imagens/br_cls_cordados.jpg": "d322fab5579a4a4d1a3da2bcc34d7dc2",
"assets/data/materiais/imagens/br_cls_exec20.jpg": "46dd719bfa6fa67791b686306b89d92d",
"assets/data/materiais/imagens/br_cls_filos_animais.jpg": "2eaaffda3b9ca72dcb974ceb13a76ee3",
"assets/data/materiais/imagens/br_cls_grupos_plantas.jpg": "3cd6298803c83ae19d79b66eb5f85ef6",
"assets/data/materiais/imagens/br_cls_hierarquia.jpg": "f10903964ad37e40479df059319d6fc4",
"assets/data/materiais/imagens/br_cls_invertebrados.jpg": "2f827188cf1b5975dda9e013b56209db",
"assets/data/materiais/imagens/br_cls_mapa_animal.jpg": "c76d4c3e5f755a87ce82ea8dcad54520",
"assets/data/materiais/imagens/br_cls_plantae.jpg": "0b9d2169c7514641745ae3893636e3c6",
"assets/data/materiais/imagens/br_cls_reinos.jpg": "59276fbe03d6e40e3f690ccca16f8b6f",
"assets/data/materiais/imagens/br_cls_reinos2.jpg": "8649e1c8d90d189ad778ca690ed38e4f",
"assets/data/materiais/imagens/br_cls_reino_animal.jpg": "7f6bb02ca489cb666572120f43ec79ec",
"assets/data/materiais/imagens/br_cls_reino_animal2.jpg": "435997f092ee2012af018a8e0d3da03c",
"assets/data/materiais/imagens/br_cls_reino_plantae.jpg": "77d07785364eaabb375cf25bdf74163f",
"assets/data/materiais/imagens/br_cls_reino_plantae2.jpg": "b4115cebaac03382aff2a9e59dd67c67",
"assets/data/materiais/imagens/br_cls_taxa.jpg": "552398f0e4a174511e9b1d78b4584e1a",
"assets/data/materiais/imagens/br_cls_taxonomia.jpg": "72b0c7c7bca9d37fb7c6dd121f713bb2",
"assets/data/materiais/imagens/br_cls_taxonomia2.jpg": "552398f0e4a174511e9b1d78b4584e1a",
"assets/data/materiais/imagens/br_cls_vertebrados.jpg": "eb0af76dd6e30a004dfd11e5d8b632f6",
"assets/data/materiais/imagens/br_eco_agua.jpg": "026a9223c9436e344f299525c36fcf34",
"assets/data/materiais/imagens/br_eco_agua_etapas.jpg": "b462e4605e561098a749e29d412dac93",
"assets/data/materiais/imagens/br_eco_biomas.jpg": "316955935a7debcdcb32837a4475fc1b",
"assets/data/materiais/imagens/br_eco_biomas_mapa.jpg": "89a04c59d132093f1a510138dcc182e1",
"assets/data/materiais/imagens/br_eco_biomas_nova.jpg": "bd7407c8c0287e8c001a875313a8b379",
"assets/data/materiais/imagens/br_eco_cadeia.jpg": "b4f8d2ba9e596ca6324c9a6d0e35aa9b",
"assets/data/materiais/imagens/br_eco_cadeia_aqua.jpg": "c7484405a413962338038831c1309088",
"assets/data/materiais/imagens/br_eco_cadeia_exemplo.jpg": "90a70937fd255a105ae1c3d67953bd80",
"assets/data/materiais/imagens/br_eco_cadeia_nova.jpg": "e21f45a6b296edf9ba5d75a098f82493",
"assets/data/materiais/imagens/br_eco_cadeia_nova2.jpg": "fce86f13b7d884f0970daa7e19d60d02",
"assets/data/materiais/imagens/br_eco_carbono.jpg": "51530fade19f6594ef5977207d19bb3a",
"assets/data/materiais/imagens/br_eco_carbono_etapas.jpg": "c94ddeecd66345b9fa4708e8610171c2",
"assets/data/materiais/imagens/br_eco_comensalismo.jpg": "241f7fd4ca1dea81c54cac6c5a481b28",
"assets/data/materiais/imagens/br_eco_efeito_estufa.jpg": "7354f0b5e60ecb2c9b2ddc3baeb350c8",
"assets/data/materiais/imagens/br_eco_fluxo.jpg": "1f481f6deba9945c0812af2890b8b00d",
"assets/data/materiais/imagens/br_eco_mapa_biomas.jpg": "3545256f8b9b453d61064cc576d39adb",
"assets/data/materiais/imagens/br_eco_mapa_mental.jpg": "0b6a98d1bcc6e1add14fbab58f56df23",
"assets/data/materiais/imagens/br_eco_nitrogenio.jpg": "40dfbbf7b1c126e70bc986d4a5c98698",
"assets/data/materiais/imagens/br_eco_nitrogenio_etapas.jpg": "cce4ef12010cf82959d8a1235d6571af",
"assets/data/materiais/imagens/br_eco_niveis.jpg": "c3542f8452c91c1874437d13e8452ba3",
"assets/data/materiais/imagens/br_eco_piramides.jpg": "a17ca24d7419f0baaf28c39152f0d4cb",
"assets/data/materiais/imagens/br_eco_relacoes.jpg": "0aafb5489119ad16ca8ed998b7b7096a",
"assets/data/materiais/imagens/br_eco_teia.jpg": "442987a15e35c33e27a4db5c205998bd",
"assets/data/materiais/imagens/br_evo_arqueopterix.jpg": "33a6b7f6f949e1ad55e67e0f3299b989",
"assets/data/materiais/imagens/br_evo_darwinismo.jpg": "239285cfa1dc72c424d4a3e6524918aa",
"assets/data/materiais/imagens/br_evo_esquema.jpg": "10e5d9f5d9a6d1fd1d5ba6bb17da256c",
"assets/data/materiais/imagens/br_evo_evidencias.jpg": "4adc6dcca953012d803d7d4c99619bf2",
"assets/data/materiais/imagens/br_evo_fosseis.jpg": "c5186543fd242ec83ae69d0454f18076",
"assets/data/materiais/imagens/br_evo_hominideos.jpg": "e6263fb5ed83334d04be2e9c9237ae1f",
"assets/data/materiais/imagens/br_evo_homologia.jpg": "d9983c906afdb23e7ce353ee6099e54b",
"assets/data/materiais/imagens/br_evo_homologias.jpg": "416a439e88afd6a2a1d587f11983842b",
"assets/data/materiais/imagens/br_evo_humanas.jpg": "416a439e88afd6a2a1d587f11983842b",
"assets/data/materiais/imagens/br_evo_lamarck.jpg": "03f034d48798460212c027a09d99cf0f",
"assets/data/materiais/imagens/br_evo_neanderthal.jpg": "c5186543fd242ec83ae69d0454f18076",
"assets/data/materiais/imagens/br_evo_origem.jpg": "ef8ae637b896431d8e84ee01802cd509",
"assets/data/materiais/imagens/br_evo_passaros.jpg": "3b986133c6815fb4c9fc7df3abe07d0b",
"assets/data/materiais/imagens/br_evo_selecao.jpg": "6326cdd90532ca55d87768713da144f4",
"assets/data/materiais/imagens/br_evo_selecao2.jpg": "f15a8c26f8d5c14b61c3b95ff5e6c9bd",
"assets/data/materiais/imagens/br_evo_tentilhoes.jpg": "a4dde5c357b04ce4b80f83e15a32c191",
"assets/data/materiais/imagens/br_evo_teoria.jpg": "21249a7cb73f376feae92826471316ab",
"assets/data/materiais/imagens/br_gam_espermiogenese.jpg": "2dd453c3fc6c64ee5f47ee540512977c",
"assets/data/materiais/imagens/br_gam_esp_fases.jpg": "7ec0a353dd8c939b60b93eff43b7b1cc",
"assets/data/materiais/imagens/br_gam_esp_me.jpg": "a894b7b3a5b3d7da4df7cf518bf0a41a",
"assets/data/materiais/imagens/br_gam_esp_ovogenese.jpg": "6120c133d75da6538d448536eaaf288d",
"assets/data/materiais/imagens/br_gam_estrutura_esp.jpg": "0088695c5b16efb09afed541d4ad7c1e",
"assets/data/materiais/imagens/br_gam_gametogenese.jpg": "05da732a2500797f1351be8b41215a0d",
"assets/data/materiais/imagens/br_gam_ovogenese_fases.jpg": "9c0c3f0c88f74a3a70a4f7602c4b0b14",
"assets/data/materiais/imagens/br_gam_ovogenese_me.jpg": "937108b45320643dc65014cd3992faec",
"assets/data/materiais/imagens/br_gen_biotecnologia.jpg": "e5a39b70344c6486c27a7706b8939722",
"assets/data/materiais/imagens/br_gen_clonagem.jpg": "e86f183cf703492c4011d66a24701f14",
"assets/data/materiais/imagens/br_gen_conceitos.jpg": "31625dca87c3bf3c8c4626e68f4b3684",
"assets/data/materiais/imagens/br_gen_cromossomos.jpg": "d676e1f1731417f8d496fab4c0500b2f",
"assets/data/materiais/imagens/br_gen_dna_recombinante.jpg": "37795751e8e0d324e1c1dfc977f8d5e1",
"assets/data/materiais/imagens/br_gen_ervilha.jpg": "b2eb0ac98cb4f462f159453da3b6af7d",
"assets/data/materiais/imagens/br_gen_gene_celula.jpg": "8086e6af0b081e73357a9cb1156fa305",
"assets/data/materiais/imagens/br_gen_hereditariedade.jpg": "0cd23ac04ff6b0f93393832fcd14a4a9",
"assets/data/materiais/imagens/br_gen_linkage.jpg": "5d12f741ad316a6281545dfc247a3455",
"assets/data/materiais/imagens/br_gen_mendel.jpg": "171e44e70d7327b8a3424d89edcb1af4",
"assets/data/materiais/imagens/br_gen_primeira_lei.jpg": "d91b6559f081a7803ca1d71615e6af3d",
"assets/data/materiais/imagens/br_hist_cartilagem.jpg": "77bcde768aea8f5dc57cead3361a5e19",
"assets/data/materiais/imagens/br_hist_conjuntivo_denso.jpg": "96d16075087943cc42d6f838d2b84d78",
"assets/data/materiais/imagens/br_hist_conjuntivo_osso.jpg": "38d4bc29cd8593f9e8676fb6fedf6773",
"assets/data/materiais/imagens/br_hist_conjuntivo_sangue.jpg": "838bbed628102e11ba607d92cb418bea",
"assets/data/materiais/imagens/br_hist_conjuntivo_tipos.jpg": "2583ce8865e91d8018828d6d27a12232",
"assets/data/materiais/imagens/br_hist_epitelial_classif.jpg": "1c41017f98e313d2766f9a808b66fec1",
"assets/data/materiais/imagens/br_hist_epitelial_forma.jpg": "6cec4ee21ebe083714ab6c5b96d54e5b",
"assets/data/materiais/imagens/br_hist_epitelial_tipos.jpg": "2c5cff4f41c74c67dc49a717f06f98df",
"assets/data/materiais/imagens/br_hist_glandulas.jpg": "86f351911ba32d5c642b5da811914b6a",
"assets/data/materiais/imagens/br_hist_muscular_cardiaco.jpg": "09b1be6e4356a13a8eb8e5bdf2eeeb0e",
"assets/data/materiais/imagens/br_hist_muscular_liso.jpg": "b9917b244518e6043a1508ac3bdf7e19",
"assets/data/materiais/imagens/br_hist_muscular_tipos.jpg": "220d971a9eb3e0131e78f302cddc16f3",
"assets/data/materiais/imagens/br_hist_neuronio.jpg": "25608c6ed4958897392ec628532dd815",
"assets/data/materiais/imagens/br_hist_neuronios_glias.jpg": "8d503ecbfd8f9cfc5f044828dca9d4a7",
"assets/data/materiais/imagens/br_hist_sarcomero.jpg": "04de4e54144dc1d84269399b816bc101",
"assets/data/materiais/imagens/br_intro_biomoleculas.jpg": "3c56934bdb6a4993bf6c5e32cb8e0881",
"assets/data/materiais/imagens/br_intro_celulas.jpg": "496d6463f8014eba93ae1907c09bd3a5",
"assets/data/materiais/imagens/br_intro_celulas2.jpg": "117521f96127e4d83ae59e2a03d6df31",
"assets/data/materiais/imagens/br_intro_celula_pro.jpg": "a6e5522d31669818643d6c95a3c75208",
"assets/data/materiais/imagens/br_intro_cientifico.jpg": "2a64152317e5e8763a960b1a0dbe516b",
"assets/data/materiais/imagens/br_intro_divisao.jpg": "fabe1f59890457fb36354599b55d6bff",
"assets/data/materiais/imagens/br_intro_endo.jpg": "15d02c305299730a9075ab4e25a477f5",
"assets/data/materiais/imagens/br_intro_endossimbiose.jpg": "c5186543fd242ec83ae69d0454f18076",
"assets/data/materiais/imagens/br_intro_mapa.jpg": "ef4167853181e1a6606cad2387dbb283",
"assets/data/materiais/imagens/br_intro_metodo.jpg": "7fc42a37cd1829ea37689cbcc9ebc56a",
"assets/data/materiais/imagens/br_intro_mitocondria.jpg": "3ce226499c0ff5fab3543231fe1f9241",
"assets/data/materiais/imagens/br_intro_nutrientes.jpg": "6b6ae571cd3d3f6d232b2366487c82a4",
"assets/data/materiais/imagens/br_intro_organelas.jpg": "9490c5369adad928af9dbad02346ba3b",
"assets/data/materiais/imagens/br_intro_origem.jpg": "15245aba3f4d6d61fe2386eed763233f",
"assets/data/materiais/imagens/br_intro_procariontes.jpg": "6f6591c573eef753b6e3369d69eebb00",
"assets/data/materiais/imagens/br_intro_procariontes2.jpg": "6f6591c573eef753b6e3369d69eebb00",
"assets/data/materiais/imagens/br_intro_seres.jpg": "219da71fdfc534122d6563c450c5c8a7",
"assets/data/materiais/imagens/br_intro_teoria.jpg": "9438b2b372823058b0d0e0d54545bae8",
"assets/data/materiais/imagens/br_meiose_be.jpg": "ba9a7b0aabacb8943f531336c5561c28",
"assets/data/materiais/imagens/br_meiose_crossing.jpg": "8305858b0497c5576c32e66f3470e3e2",
"assets/data/materiais/imagens/br_meiose_etapas.jpg": "8fefaefd5e6d29e996deca7766f4b761",
"assets/data/materiais/imagens/br_meiose_tm.jpg": "34854b0c99f43e47f21932c9f41f2970",
"assets/data/materiais/imagens/br_membrana_infoescola.jpg": "8fc18a1aa0602465075976d472a0994c",
"assets/data/materiais/imagens/br_membrana_mundoeducacao.jpg": "9f2f6a2e696bf6c43732b608cf2f1025",
"assets/data/materiais/imagens/br_met_ciclo_calvin.jpg": "95194e129de10fb9518680332b9b519f",
"assets/data/materiais/imagens/br_met_cloroplasto.jpg": "266638e8b0b83fa78e60fc4d958aed94",
"assets/data/materiais/imagens/br_met_fase_clara.jpg": "1b60306fbd8fe1fd33da6fb7894e64ff",
"assets/data/materiais/imagens/br_met_fase_escura.jpg": "b51eaa4723722811369d74d180679fc4",
"assets/data/materiais/imagens/br_met_fermentacao.jpg": "53ca8648dcf27cf9b0bd83c6c34acc09",
"assets/data/materiais/imagens/br_met_fermentacao_me1.jpg": "9c009bb5467515e39c4bcec5202311dd",
"assets/data/materiais/imagens/br_met_fermentacao_me2.jpg": "d4359ab278c5296d6e966d797d51bd4e",
"assets/data/materiais/imagens/br_met_fermentacao_tm.jpg": "9a39792b28417984c565d54442b4f8cd",
"assets/data/materiais/imagens/br_met_fosforilacao.jpg": "ebf8169bb659825c5dc981f040ba9943",
"assets/data/materiais/imagens/br_met_fotossintese.jpg": "16f59e52fa67efab710328e5e6b96cf7",
"assets/data/materiais/imagens/br_met_fotossintese_tm.jpg": "0d9abecae9cd9e509329920405d4990b",
"assets/data/materiais/imagens/br_met_glicolise.jpg": "ecd365e7ed18cea87284748e203a3259",
"assets/data/materiais/imagens/br_met_glicolise_tm.jpg": "3364aead7ab3a4ed9abb0f307ba5a07b",
"assets/data/materiais/imagens/br_met_krebs_be.jpg": "4c7d8b7b49998f125308e4ad7459bf75",
"assets/data/materiais/imagens/br_met_krebs_tm.jpg": "dbdee5389aee1eeaf4e9e35081f03b06",
"assets/data/materiais/imagens/br_met_respiracao_be.jpg": "3878992d9a4eb959ee6748642ea4a990",
"assets/data/materiais/imagens/br_met_respiracao_me.jpg": "7158091af1cceef727c2504eb7ad49fb",
"assets/data/materiais/imagens/br_met_respiracao_tm.jpg": "83ca636ff08ee78a935d09614c9c4a8d",
"assets/data/materiais/imagens/br_mic_algas.jpg": "26d1660675e60af774f06047bed35f90",
"assets/data/materiais/imagens/br_mic_algas2.jpg": "50739dcaed70bbe35ca9ae1fa19580f7",
"assets/data/materiais/imagens/br_mic_algas_verdes.jpg": "3eb56da2b8e0677a9c5fbc59e4f960c2",
"assets/data/materiais/imagens/br_mic_bacterias_classif.jpg": "0c0cd52f143b78722cfcedea38641596",
"assets/data/materiais/imagens/br_mic_bacterias_mapa.jpg": "ba8a4e1b8ef0d9f0eb3ceedf73a73a2a",
"assets/data/materiais/imagens/br_mic_bacterias_repro.jpg": "fc565d5ce3245a99a7d2270e60913dce",
"assets/data/materiais/imagens/br_mic_fungos.jpg": "83964a326f54732445534bca6b1770f3",
"assets/data/materiais/imagens/br_mic_fungos2.jpg": "f19636b9a8d28dc9c7b18f75ae933c5c",
"assets/data/materiais/imagens/br_mic_fungos3.jpg": "cce09e6aa6debaa24488acff60f2443f",
"assets/data/materiais/imagens/br_mic_fungos_classif.jpg": "eef8d8991e7775ef04d0ddf7c6efac38",
"assets/data/materiais/imagens/br_mic_protozoarios.jpg": "38821d5de2ce02e9c98c0056be796f32",
"assets/data/materiais/imagens/br_mic_tipos_bacterias.jpg": "702a23367f45b3603aee2402369aa8ff",
"assets/data/materiais/imagens/br_mic_virus_estrutura.jpg": "d7ba59b755e0bb8117004c47611b1232",
"assets/data/materiais/imagens/br_mic_virus_mapa.jpg": "80d4cfc069f93115a69a8eb0dbe31570",
"assets/data/materiais/imagens/br_mic_virus_replicacao.jpg": "4038264992d27d269039a6c2645df2b9",
"assets/data/materiais/imagens/br_mitose_citocinese.jpg": "dbff00573e01adba011d3070615e3702",
"assets/data/materiais/imagens/br_mitose_fases.jpg": "9951ccee068b1c620b891badf2ec68f1",
"assets/data/materiais/imagens/br_mitose_tm.jpg": "e63d71b9c5bf9f0e671e0307c9578e03",
"assets/data/materiais/imagens/br_mosaico_brasilescola.jpg": "f96c83bd35b8b234506bc06235fc9dee",
"assets/data/materiais/imagens/br_nuc_cariotipo_be.jpg": "ec35f77b3e8e942b95cc5db63f230e99",
"assets/data/materiais/imagens/br_nuc_cariotipo_humano.jpg": "3995665a17d9f0b5275f7cd66d561b7b",
"assets/data/materiais/imagens/br_nuc_cromossomos.jpg": "14329f3891f37710555347affcc8a2f8",
"assets/data/materiais/imagens/br_nuc_cromossomo_estrutura.jpg": "d584f74c0af43a32359b75d096bfc109",
"assets/data/materiais/imagens/br_nuc_cromossomo_me.jpg": "baacf8bfb0679f642d38d96bab0b385c",
"assets/data/materiais/imagens/br_nuc_nucleo_1.jpg": "c23b7cb0898d813076901ddf952eaf11",
"assets/data/materiais/imagens/br_nuc_nucleo_2.jpg": "47afe41512d511d73aca8f49cc17139e",
"assets/data/materiais/imagens/br_nuc_nucleo_3.jpg": "81cc1bf2b16446d959e3c948e70b3b71",
"assets/data/materiais/imagens/br_nuc_tipos_cromossomo.jpg": "8b416aa33a1963c1c490d6dc37ac5a15",
"assets/data/materiais/imagens/br_org_golgi.jpg": "ca7bb26e3186895ed501baab8c54adb1",
"assets/data/materiais/imagens/br_org_golgi_faces.jpg": "a987febf41c6fb2c6799655b7290c477",
"assets/data/materiais/imagens/br_org_mitocondria.jpg": "3eb31af6958b1ebc2338d9563cd27cdf",
"assets/data/materiais/imagens/br_org_mitocondria_estrutura.jpg": "3ce226499c0ff5fab3543231fe1f9241",
"assets/data/materiais/imagens/br_org_organelas_1.jpg": "156a9e0d222deca4f0b6f2242bbbb721",
"assets/data/materiais/imagens/br_org_organelas_2.jpg": "aa1741edb1d85cb2d6862534199b7e3d",
"assets/data/materiais/imagens/br_org_reticulo.jpg": "2d63c998fed8360da5ad50b9613cad0a",
"assets/data/materiais/imagens/br_org_ribossomo.jpg": "d8e8323b7e1155162562e9c99ea77f40",
"assets/data/materiais/imagens/br_osmose_animal.jpg": "4a50f564b4a92d201d0409269c98b278",
"assets/data/materiais/imagens/br_osmose_processo.jpg": "d3b3c898ac23ab2b78e262f7a9f72386",
"assets/data/materiais/imagens/br_osmose_vegetal.jpg": "e8bd6272ca1b2a08bc5fd1bddc3b5692",
"assets/data/materiais/imagens/br_qui10_endoexo.jpg": "6b059a377647f3f13867f7e35b6eb393",
"assets/data/materiais/imagens/br_qui10_entalpia_form.jpg": "297e75d51f6afde5bca569acaa194860",
"assets/data/materiais/imagens/br_qui10_hess.jpg": "744bed666945613513c2e09b181a3d75",
"assets/data/materiais/imagens/br_qui10_termo.jpg": "fb570265ad70232fa93e4972a5b77b44",
"assets/data/materiais/imagens/br_qui11_ativacao.jpg": "d10ae08e35e699de68a7c1c291b18666",
"assets/data/materiais/imagens/br_qui11_cinetica.jpg": "0cfab2ded4fda98c610302962a5e5a74",
"assets/data/materiais/imagens/br_qui11_equilibrio.jpg": "8eef87fdc18b92906126da9034d7a459",
"assets/data/materiais/imagens/br_qui11_grafico.jpg": "ea16bea6b28ee405bec45a5d6b7ec439",
"assets/data/materiais/imagens/br_qui11_ph.jpg": "3611a3fb72b07754778431573c484b3e",
"assets/data/materiais/imagens/br_qui11_velocidade.jpg": "b74977138d527960fc572f4d4326ba78",
"assets/data/materiais/imagens/br_qui13_benzeno.jpg": "cf795bf7d73033c4a15464c9666c5a44",
"assets/data/materiais/imagens/br_qui13_cadeias.jpg": "9821b700c1c797f50e24fb2b2a5884ca",
"assets/data/materiais/imagens/br_qui13_classif_cadeias.jpg": "ec7202af621981f43aaf86261f75f421",
"assets/data/materiais/imagens/br_qui13_compostos.jpg": "a3814f728e4fb7145d8f17ba9dfa94ad",
"assets/data/materiais/imagens/br_qui13_funcoes.jpg": "0a6fc2bb0396ed8bad7f0ea1c9c669cd",
"assets/data/materiais/imagens/br_qui13_hidrocarbonetos.jpg": "a49e5d10013faf1a858822e3183112b5",
"assets/data/materiais/imagens/br_qui13_isomeria.jpg": "8d05378045476218feca95839f9ca43f",
"assets/data/materiais/imagens/br_qui13_organica2.jpg": "0d1cdfddc8cd8c9e9b504a17a4a23e84",
"assets/data/materiais/imagens/br_qui1_alotropia.jpg": "b3473da34a9014481e61098511b217da",
"assets/data/materiais/imagens/br_qui1_destilacao.jpg": "29916cf3e82ef4111cdb9bdd5c6e6117",
"assets/data/materiais/imagens/br_qui1_estados.jpg": "4b6f700e56cd1f4c43fba315c80d1145",
"assets/data/materiais/imagens/br_qui1_misturas.jpg": "57d7dd400269e2daca8063da3b3eafe7",
"assets/data/materiais/imagens/br_qui1_mudancas.jpg": "b4f3957b18976ed94d591882afe0d82e",
"assets/data/materiais/imagens/br_qui1_propriedades.jpg": "d8995c8cff4b0def57e4f040324f6197",
"assets/data/materiais/imagens/br_qui1_separacao.jpg": "2294f5ba9bdf7b0f9e19ab758e8cd816",
"assets/data/materiais/imagens/br_qui1_substancias.jpg": "d2c1fc7c9f6b42809b69addd89584098",
"assets/data/materiais/imagens/br_qui2_atomo.jpg": "3e16450eae1becd3d7412ff14377a30e",
"assets/data/materiais/imagens/br_qui2_bohr.jpg": "ee18fff0bc637d25cdf139619d9bdb1b",
"assets/data/materiais/imagens/br_qui2_dalton.jpg": "91461c5bf02fc48cc13f11eeef6236a6",
"assets/data/materiais/imagens/br_qui2_evolucao.jpg": "3f1461a798e13ebc5dbd67e3f6868a64",
"assets/data/materiais/imagens/br_qui2_isotopos.jpg": "1b34981265748791c80ba06463d9cdc8",
"assets/data/materiais/imagens/br_qui2_rutherford.jpg": "8f4031f4e94ea9c591ad18861641b77b",
"assets/data/materiais/imagens/br_qui2_thomson.jpg": "13cc3d5e58d1d62bbcb699fc5ec61a2d",
"assets/data/materiais/imagens/br_qui3_familias.jpg": "6ec1d5b804a2b625975c351f3087711b",
"assets/data/materiais/imagens/br_qui3_propriedades.jpg": "36f6ac519abdb331bc338d9da4fd3fd0",
"assets/data/materiais/imagens/br_qui3_raio.jpg": "2f7b0d46b9c7e3eb23e5abccf9f4336a",
"assets/data/materiais/imagens/br_qui3_tabela.jpg": "6d8275776a0c1e26188d8129d82d194b",
"assets/data/materiais/imagens/br_qui3_tabela_grande.jpg": "b8953c54485528e713a093e0fe085c88",
"assets/data/materiais/imagens/br_qui4_covalente.jpg": "a51ddaf75fafb535bbb22ad266074831",
"assets/data/materiais/imagens/br_qui4_covalente2.jpg": "4184e7a757b2c6eab75ac80aa8ca2a62",
"assets/data/materiais/imagens/br_qui4_geometria.jpg": "66fca0573aa878c1ad2c5fd430e49275",
"assets/data/materiais/imagens/br_qui4_ionica.jpg": "75486e0735dc5f1736983a2faafcbce9",
"assets/data/materiais/imagens/br_qui4_ionica2.jpg": "f629167ada7ea0347f7aeff3e6729b18",
"assets/data/materiais/imagens/br_qui4_metalica.jpg": "3e170aae6f767b59db9110c556630982",
"assets/data/materiais/imagens/br_qui4_polar.jpg": "eb72d8ea8da8e51f1d456f5304560981",
"assets/data/materiais/imagens/br_qui5_balanceamento.jpg": "1496f35d136cf1ca54eb8b919ab3a28b",
"assets/data/materiais/imagens/br_qui5_reacoes.jpg": "0315c19808d2bf6553045bc1baf53322",
"assets/data/materiais/imagens/br_qui6_acidos.jpg": "0f7d32feba25f57b302a7a67cc5dc452",
"assets/data/materiais/imagens/br_qui6_oxidos.jpg": "8fea6772a2e465cbc456f6fbeb1386bf",
"assets/data/materiais/imagens/br_qui6_reacoes_endo.jpg": "433a05bb34f680edcb791afecd994bbf",
"assets/data/materiais/imagens/br_qui7_estequio.jpg": "8e7928b4dc3329443a41b8d287628be0",
"assets/data/materiais/imagens/br_qui7_leis.jpg": "9c845ee4d51714b09b259150c0b8d671",
"assets/data/materiais/imagens/br_qui7_molaridade.jpg": "d1be321d3d2fcf0adc9541cbfc7a4706",
"assets/data/materiais/imagens/br_qui8_leis.jpg": "2390eb6e1a1752705af10b27b95931e5",
"assets/data/materiais/imagens/br_qui9_diluicao.jpg": "15e2403fd3f2501a9513d6b4794f7b67",
"assets/data/materiais/imagens/br_rep_anexos.jpg": "1e33bcda711b34c9748e7312385f42a5",
"assets/data/materiais/imagens/br_rep_anexos_tm.jpg": "0311efbb48fe552f171f29273477f4ba",
"assets/data/materiais/imagens/br_rep_brotamento.jpg": "5760ebfeb42047b4652d2a2a1f3a25b0",
"assets/data/materiais/imagens/br_rep_contracep.jpg": "51ab6f721c66d14ea9589b7d3b29928d",
"assets/data/materiais/imagens/br_rep_diu.jpg": "946a28a8757e88893974706d46b34646",
"assets/data/materiais/imagens/br_rep_divisao_binaria.jpg": "3722a8c0f2a0796143273853747d4de3",
"assets/data/materiais/imagens/br_rep_fecundacao.jpg": "ec1cbd36b5a36a34f1f864c6bdafb68d",
"assets/data/materiais/imagens/br_rep_folhetos.jpg": "ea5f7250c72ce6246d4cd392f27c9d3b",
"assets/data/materiais/imagens/br_rep_folhetos_ie.jpg": "d4a71b03d12040fdf33067d7d0b9e88d",
"assets/data/materiais/imagens/br_rep_fragmentacao.jpg": "68444ec3cb668c5bab59d608b3fd2aca",
"assets/data/materiais/imagens/br_rep_placenta.jpg": "62c54ea38d105debb80eb1e62064cbf9",
"assets/data/materiais/imagens/br_rep_sist_fem.jpg": "5fc1824d21839c26a05b590cc97e652c",
"assets/data/materiais/imagens/br_rep_sist_masc.jpg": "00f4eec7cf78d157c972ac2d13e3c9ca",
"assets/data/materiais/imagens/br_sau_anticorpo.jpg": "269f6347985f42b25d233f36965896c4",
"assets/data/materiais/imagens/br_sau_fagocitose.jpg": "5f618da2f81908ea714e233d85fa0fa2",
"assets/data/materiais/imagens/br_sau_orgaos.jpg": "e7e2c52e3fb7097abd1682f65897a053",
"assets/data/materiais/imagens/br_sau_resposta.jpg": "91703eab359a09bd8283c0daad25408f",
"assets/data/materiais/imagens/br_sau_sistema.jpg": "e6f403fa3a67b8cd8a3ffd472f15fa6e",
"assets/data/materiais/imagens/br_sau_sistema2.jpg": "8821b4ff2ffeb3162d1d37c461d1f21f",
"assets/data/materiais/imagens/br_sau_tabela.jpg": "f15bc849ac30f36d7a099e6f7b74225e",
"assets/data/materiais/imagens/br_sau_tipos_imunidade.jpg": "8173e45d3093bf760e531f9e7196ee85",
"assets/data/materiais/imagens/br_sau_vacina.jpg": "df0ebb296ee34ee916710b9eafd40c8b",
"assets/data/materiais/imagens/br_todamateria_3d.jpg": "d68fa4f00b72f273099aa78bd3a0af6e",
"assets/data/materiais/imagens/br_todamateria_bicamada.jpg": "c695da4e92d3a49ab790a14f491808e2",
"assets/data/materiais/imagens/br_todamateria_membrana.jpg": "cac574d338b416062b0857f74f287f9a",
"assets/data/materiais/imagens/br_transporte_mundoeducacao.jpg": "176ce1ac375e65e674e5fb396ca86253",
"assets/data/materiais/imagens/br_zoo_animais_classif.jpg": "0fa2242ba7107de3d5ed6e60c68d6730",
"assets/data/materiais/imagens/br_zoo_artr%25C3%25B3podes.jpg": "8cf30c564ac394d98acfe0dbbdcad335",
"assets/data/materiais/imagens/br_zoo_artropodes2.jpg": "e16ca77052b5ce06571d72e65ee1f71e",
"assets/data/materiais/imagens/br_zoo_aves.jpg": "89ffb7c00a268a76c0c2b2e9ad7ef6b1",
"assets/data/materiais/imagens/br_zoo_esponja.jpg": "2f827188cf1b5975dda9e013b56209db",
"assets/data/materiais/imagens/br_zoo_estrela.jpg": "4501bbfe1091afba189bdd9995657b26",
"assets/data/materiais/imagens/br_zoo_hidra.jpg": "0268f703b6741c55b7bfcdd6dde3d6a6",
"assets/data/materiais/imagens/br_zoo_jiboia.jpg": "d322fab5579a4a4d1a3da2bcc34d7dc2",
"assets/data/materiais/imagens/br_zoo_libelula.jpg": "b2b31c7ac4f4bb602b1d5fe6270aa6a1",
"assets/data/materiais/imagens/br_zoo_lombriga.jpg": "acbd1712c002986dd5dbf4cee65267c1",
"assets/data/materiais/imagens/br_zoo_mamiferos.jpg": "c064f11aa59408c632b880396cb6f0c9",
"assets/data/materiais/imagens/br_zoo_mamiferos2.jpg": "80aa3f4a77867686ab44f7d98bb3670f",
"assets/data/materiais/imagens/br_zoo_minhoca.jpg": "291a63d790919419a10c0bd8e01a6d74",
"assets/data/materiais/imagens/br_zoo_peixes.jpg": "189b9946421170ddf1dbaaa6ace630d9",
"assets/data/materiais/imagens/br_zoo_polvo.jpg": "d1159b882fc1755cb48ae6417f3f16e2",
"assets/data/materiais/imagens/br_zoo_reino.jpg": "7f6bb02ca489cb666572120f43ec79ec",
"assets/data/materiais/imagens/br_zoo_tenia.jpg": "336bd6e045dbeb898e7949408545592e",
"assets/data/materiais/imagens/br_zoo_vertebrados.jpg": "718fac7c074e3fe346a29026f061fc8c",
"assets/data/materiais/imagens/celula_geral_1.jpg": "865b61a6401d8cf4d50cf97213ee5adc",
"assets/data/materiais/imagens/diag_bicamada.png": "eee9d1f7f44c77d1f495fcb9aed435c9",
"assets/data/materiais/imagens/diag_componentes.png": "59905dc3dd3a046787412366100e5d9d",
"assets/data/materiais/imagens/diag_endocitose.png": "974c74f634c11def0857a7c3263569c1",
"assets/data/materiais/imagens/diag_osmose.png": "339f77a4943804edb28095d69d9aa9b8",
"assets/data/materiais/imagens/diag_transporte.png": "e37aeeb56955aa9398926949029ef597",
"assets/data/materiais/imagens/esp_comprension.png": "d92d9477f1e569975c4d69e1342ba96a",
"assets/data/materiais/imagens/esp_comp_capa.jpg": "dd519356cf650c9cd3258ba2e6c62875",
"assets/data/materiais/imagens/esp_gramatica.png": "67b6c1d221aae0b69fa20e067e06b177",
"assets/data/materiais/imagens/esp_gram_capa.jpg": "a0834752dd43a04638022c12dfde4dae",
"assets/data/materiais/imagens/esp_semantica.png": "06d0064a535836dd010cc07b59fef0e2",
"assets/data/materiais/imagens/esp_sem_capa.png": "acd2a199553cd2603d248ca7fb3ca32a",
"assets/data/materiais/imagens/esp_sem_capa_v2.jpg": "916e74a0a1b60e72351f1a1c37013aa2",
"assets/data/materiais/imagens/filo_conhecimento.png": "f265d13717d8fc9ea30e67651dc92c7c",
"assets/data/materiais/imagens/filo_conhec_real1.png": "7ade77bc7184b5b549cf30225a5832e8",
"assets/data/materiais/imagens/filo_conhec_real2.jpg": "1e36477a12071c6581f0de0469c2e8b1",
"assets/data/materiais/imagens/filo_con_capa.jpg": "2b044c287a0a39fb351ec2df0b0fcdd3",
"assets/data/materiais/imagens/filo_cultura.png": "0301f1b6f89648f89b1c9dd85dbe95bb",
"assets/data/materiais/imagens/filo_cultura_real1.jpg": "c6ca6cfca84b572d859c4a77daee99f8",
"assets/data/materiais/imagens/filo_cultura_real2.jpg": "0a475a2e5eaff350b46cb0799c6d2391",
"assets/data/materiais/imagens/filo_cult_capa.png": "9dfa67dbee708fff7f0ccad05c92fe56",
"assets/data/materiais/imagens/filo_estetica.png": "a269eaa44dcd11e1c0f9fb0ff6a4ed88",
"assets/data/materiais/imagens/filo_estetica_real1.jpg": "8adbdae95318ce8297d68240c1df2afe",
"assets/data/materiais/imagens/filo_estetica_real2.jpg": "dc3cf64f091d826ba8c4472130c4a108",
"assets/data/materiais/imagens/filo_est_capa.jpg": "d311202c21158cbc3164c5056648212f",
"assets/data/materiais/imagens/filo_etica.png": "c57e6b52ed3af541fb4aaf2221be2d9f",
"assets/data/materiais/imagens/filo_etica_real1.jpg": "70a8e128502c7910e658513110e8d011",
"assets/data/materiais/imagens/filo_etica_real2.jpg": "b3b15b1b4c434a67b114df405da91c97",
"assets/data/materiais/imagens/filo_et_capa.jpg": "fd3dceb050b61422f2d8cda61299d7db",
"assets/data/materiais/imagens/filo_filosofia.png": "09894d2456a30d5cf8c570164773e431",
"assets/data/materiais/imagens/filo_filos_capa.jpg": "f78d4b53d62cf913319ca6fc41f205ce",
"assets/data/materiais/imagens/filo_filos_real1.jpg": "2c94c943f3b8ee618be475a7b4ac147c",
"assets/data/materiais/imagens/filo_filos_real2.jpg": "02d7c84f5ef9c40297a9d19c88d14eb6",
"assets/data/materiais/imagens/filo_logica.png": "a5a314fe4072ca56bb6eca650232c1c8",
"assets/data/materiais/imagens/filo_logica_real1.jpg": "8adbdae95318ce8297d68240c1df2afe",
"assets/data/materiais/imagens/filo_logica_real2.jpg": "d04f35385b8b9f31f757e852d25c857d",
"assets/data/materiais/imagens/filo_log_capa.jpg": "de56710c8c9e29bf3a099d803ff049aa",
"assets/data/materiais/imagens/filo_politica.png": "b062107b1f5d6179e6e182bfe5dda1f9",
"assets/data/materiais/imagens/filo_politica_real1.jpg": "2c94c943f3b8ee618be475a7b4ac147c",
"assets/data/materiais/imagens/filo_politica_real2.jpg": "02d7c84f5ef9c40297a9d19c88d14eb6",
"assets/data/materiais/imagens/filo_pol_capa.jpg": "fa7ef6a8e0f2cc7f19b912bef0e04e60",
"assets/data/materiais/imagens/fi_cinematica.png": "fd5697449abcb293540dfbbff6c9d3a9",
"assets/data/materiais/imagens/fi_cinem_capa.gif": "eb1fd63397c42d983a1342212e6134b9",
"assets/data/materiais/imagens/fi_dinamica.png": "72bd2c3bfee89ea93e7092b45698333b",
"assets/data/materiais/imagens/fi_dinam_capa.gif": "eb1fd63397c42d983a1342212e6134b9",
"assets/data/materiais/imagens/fi_dinam_capa_v2.jpg": "4197388d06e1e91d8c89eff039175524",
"assets/data/materiais/imagens/fi_eletrodinamica.png": "643d55c0cf4c97272d8acfb7a06ab0b9",
"assets/data/materiais/imagens/fi_eletrodin_capa.jpg": "06e8bb0bd391f6dce12a74818046f206",
"assets/data/materiais/imagens/fi_eletromagnetismo.png": "cddaef61b1166a55406ddb7052e08a90",
"assets/data/materiais/imagens/fi_eletromag_capa.jpg": "2c2d44ee19345322fc59ea521e55db80",
"assets/data/materiais/imagens/fi_eletrostatica.png": "d0aee82e95fd167a54fd56b83cc87393",
"assets/data/materiais/imagens/fi_eletrost_capa.png": "84b730509d9b112041cb1f226e06690d",
"assets/data/materiais/imagens/fi_fisica_moderna.png": "2a0070c4ff519653652f38d9d8bb10b5",
"assets/data/materiais/imagens/fi_grandezas.png": "4fe5bca375d7da5a804a31a2c8440ffc",
"assets/data/materiais/imagens/fi_grand_capa.jpg": "74ebb71173b8a7a3d19252dd77f2141f",
"assets/data/materiais/imagens/fi_hidrostatica.png": "9c803271790a99a97c383dd806c36b99",
"assets/data/materiais/imagens/fi_hidro_capa.png": "6a2fa86931235baf5f90f470284f9846",
"assets/data/materiais/imagens/fi_moderna_capa.jpg": "bb4039bceb67df324c7d481c27d8166c",
"assets/data/materiais/imagens/fi_onda_capa.gif": "a14b982d14628eb6b39aab2170761097",
"assets/data/materiais/imagens/fi_ondulatoria.png": "c145a6075a7f0096f93a3cd1c98d1713",
"assets/data/materiais/imagens/fi_optica.png": "d9693dd7f897f43cbdf84394ed4ddb14",
"assets/data/materiais/imagens/fi_optica_capa.png": "a4aa935e478a73e2cd7494e5ab19e714",
"assets/data/materiais/imagens/fi_termologia.png": "42c90d151b7ccd8e522b0d1422aa0182",
"assets/data/materiais/imagens/fi_termo_capa.png": "ae5a87429f7f50e1a410b14139007a05",
"assets/data/materiais/imagens/fi_termo_capa_v2.png": "02461ad4077f1ca6c047f6698bd5744e",
"assets/data/materiais/imagens/geo_contemporaneos.png": "4156804fec74aebe13bef1b499d0fe29",
"assets/data/materiais/imagens/geo_contemp_real1.jpg": "bc08dc1f7263f4dc8618ae2ae468e046",
"assets/data/materiais/imagens/geo_contemp_real2.jpg": "5eff65583a166c8c19309cc1f6b07d7f",
"assets/data/materiais/imagens/geo_cont_capa.jpg": "bc08dc1f7263f4dc8618ae2ae468e046",
"assets/data/materiais/imagens/geo_fisica.png": "0f53400369994a3946b9ab85568fe35e",
"assets/data/materiais/imagens/geo_fisica_real1.jpg": "63f2f3dc20b11b11b90915a8c930199f",
"assets/data/materiais/imagens/geo_fisica_real2.png": "9a4e116dc6af9f41316d335264eb4370",
"assets/data/materiais/imagens/geo_fis_capa.jpg": "63f2f3dc20b11b11b90915a8c930199f",
"assets/data/materiais/imagens/geo_humana.png": "afad678385d0f73a7a22131b2a9d7694",
"assets/data/materiais/imagens/geo_humana_real1.gif": "7225cd3079b90d31fc88ff7796f9a2be",
"assets/data/materiais/imagens/geo_humana_real2.png": "d836ab9e415ea19db50fe92ad2461d22",
"assets/data/materiais/imagens/geo_hum_capa.gif": "ef74f20a0b31b41c68008a2e7d25d688",
"assets/data/materiais/imagens/geo_maranhao.png": "78bad27de1abed8c583775b1e5f5c274",
"assets/data/materiais/imagens/geo_ma_capa.jpg": "c0aad22010097c7e97a99e4d34e249b3",
"assets/data/materiais/imagens/geo_ma_capa_v2.jpg": "44ee7240778dddbc6c9dae892b9baf0c",
"assets/data/materiais/imagens/geo_ma_real1.jpg": "745e6ff7ca7827ce412deaea7e1e7116",
"assets/data/materiais/imagens/geo_ma_real2.jpg": "296606fd5b01fdda66fd7ec059db85fc",
"assets/data/materiais/imagens/hist_antigo_real1.jpg": "aa5f010812123b8986ea0710381563c8",
"assets/data/materiais/imagens/hist_antigo_real2.jpg": "85827f51955d322e1d23f54b36678100",
"assets/data/materiais/imagens/hist_brasil_contemporaneo.png": "842218d4afed67526153bb7c248c8290",
"assets/data/materiais/imagens/hist_brasil_real_real1.jpg": "cd93b1ea16beaa88fa311d4b41f8bf1e",
"assets/data/materiais/imagens/hist_brasil_real_real2.jpg": "2a2a185b8cbfebe381730019fdd936eb",
"assets/data/materiais/imagens/hist_contemporanea.png": "2de7d08c5c7e70f7ce5db0ac7446d38a",
"assets/data/materiais/imagens/hist_contemp_real_real1.jpg": "9f3f0a76e12d38659eed3b9e8de2cf96",
"assets/data/materiais/imagens/hist_contemp_real_real2.jpg": "0f325294cd5f221026a97eb7993c9173",
"assets/data/materiais/imagens/hist_maranhao.png": "9ae7adecc8b7cd7cf247513b0d195e23",
"assets/data/materiais/imagens/hist_ma_real_real1.jpg": "745e6ff7ca7827ce412deaea7e1e7116",
"assets/data/materiais/imagens/hist_ma_real_real2.jpg": "296606fd5b01fdda66fd7ec059db85fc",
"assets/data/materiais/imagens/hist_medieval.png": "ceca54aabbae71b1b9510706135f70e2",
"assets/data/materiais/imagens/hist_medieval_real_real1.jpg": "f96fecde9b6ecd82047e0f6316520404",
"assets/data/materiais/imagens/hist_medieval_real_real2.jpg": "ce229974a73cba67e6c1371567cb9a3e",
"assets/data/materiais/imagens/hist_moderna.png": "d722084f8ad968a823dfe731fdaec7bb",
"assets/data/materiais/imagens/hist_moderna_real_real1.jpg": "07389d08a51885d4e8a277c3b5a5359c",
"assets/data/materiais/imagens/hist_moderna_real_real2.jpg": "0c9eeeee9bceec8b878c36abde3e3a07",
"assets/data/materiais/imagens/hist_mundo_antigo.png": "db8a69c76bad56c266dd26667fa0d6d1",
"assets/data/materiais/imagens/his_antigo_capa.png": "f613b4d793f58fc289cff55c10a302ed",
"assets/data/materiais/imagens/his_brasil_capa.jpg": "bbe72eb5dd92a20d26248bcb9e3695e5",
"assets/data/materiais/imagens/his_contemp_capa.jpg": "1224333b17557d78aeba2112fd6f1ccc",
"assets/data/materiais/imagens/his_ma_capa.jpg": "c0aad22010097c7e97a99e4d34e249b3",
"assets/data/materiais/imagens/his_medieval_capa.png": "e85b313421f369fd0f4b611c57725804",
"assets/data/materiais/imagens/his_moderna_capa.jpg": "6f6731ef6d67db805954de6dfb645d80",
"assets/data/materiais/imagens/ing_gramatica.png": "2113c4625141f6b39fc58ac5602707de",
"assets/data/materiais/imagens/ing_gram_capa.jpg": "db83b422cae151a96f107212684fe87a",
"assets/data/materiais/imagens/ing_gram_capa_v2.png": "8fa97b0df8b623ab6f5b9e1ba5929f42",
"assets/data/materiais/imagens/ing_leitura.png": "338ffd86e9ee7e789b5e43b5a276e43b",
"assets/data/materiais/imagens/ing_leit_capa.jpg": "db83b422cae151a96f107212684fe87a",
"assets/data/materiais/imagens/ing_lexico.png": "1bc151535de7f3ecd2a919182d864045",
"assets/data/materiais/imagens/ing_lex_capa.jpg": "ca1da546235321e7705d8636b975a8e6",
"assets/data/materiais/imagens/ing_lex_capa.png": "8fa97b0df8b623ab6f5b9e1ba5929f42",
"assets/data/materiais/imagens/mat_aritmetica.png": "a39d74c7313fb12678edf2f0ae723944",
"assets/data/materiais/imagens/mat_combinatoria.png": "64deaf4fe51de7205698168fd0d890f1",
"assets/data/materiais/imagens/mat_conjuntos.png": "797405f7d61f9c3965681cd34b0063dc",
"assets/data/materiais/imagens/mat_estatistica.png": "645774201a26337d3a60a8f4f9b81645",
"assets/data/materiais/imagens/mat_funcoes.png": "2e80c5d91186351ceb111b5f0b98e05b",
"assets/data/materiais/imagens/mat_geo_analitica.png": "90a8edd255007e7432c6505fc4b21445",
"assets/data/materiais/imagens/mat_geo_espacial.png": "a2dda6ad32d58d749eb3f00f31b8e455",
"assets/data/materiais/imagens/mat_geo_plana.png": "cd4370173ff85f481fcab62ec09bc401",
"assets/data/materiais/imagens/mat_matrizes.png": "c76f71d7dc70a3c8d684b27c863ff100",
"assets/data/materiais/imagens/mat_trigonometria.png": "70a8655a1e223b2f3c2f11277dfe2021",
"assets/data/materiais/imagens/membrana_1.png": "59d4b122bee8a7c30ced514773661de2",
"assets/data/materiais/imagens/membrana_2.png": "60f59df6f3293968f8cbb6356df8cb2b",
"assets/data/materiais/imagens/membrana_3.png": "ed7d70dba0bcfe3b95af7bcc1ae251fc",
"assets/data/materiais/imagens/membrana_4.png": "03a002db1d17a40241d325d336518acb",
"assets/data/materiais/imagens/membrana_5.png": "7dc481f48a2be818a9f6b33289ce57a5",
"assets/data/materiais/imagens/membrana_6.png": "69abe97fc70cee59f93be9600ddb3f6e",
"assets/data/materiais/imagens/membrana_v2_1.png": "d50649b3c85dfd4f0196ee0cee54d04c",
"assets/data/materiais/imagens/membrana_v2_2.png": "601740351eccf3b3c819c0c19baa3482",
"assets/data/materiais/imagens/membrana_v2_3.png": "0844ad869fa92ffa230396e63fec71d5",
"assets/data/materiais/imagens/membrana_v2_4.jpg": "909c77fd24813d8ea51ceedc4fb6175f",
"assets/data/materiais/imagens/membrana_v2_4.png": "9e1669eeba07476c8017202cda38c392",
"assets/data/materiais/imagens/membrana_v2_5.png": "d244c515ca5bd734eb0dac7e41c91f03",
"assets/data/materiais/imagens/membrana_v2_6.jpg": "f6059608792c8fec35a93a81862da86e",
"assets/data/materiais/imagens/membrana_v2_6.png": "7708fec7ad8ba18769422080f02773f6",
"assets/data/materiais/imagens/membrana_v9_1.png": "31c4f16397b9da98360ed2605aeed1cf",
"assets/data/materiais/imagens/membrana_v9_1.svg": "8222c1b6bcee68920129a86d6f3ee8d0",
"assets/data/materiais/imagens/membrana_v9_2.png": "1033bd2a9962d4dc794f2016145a98f0",
"assets/data/materiais/imagens/membrana_v9_2.svg": "4dc44c1edc75ce968e0bb66468397d84",
"assets/data/materiais/imagens/membrana_v9_3.png": "44012b2b0a469a288dbc36a6939806d5",
"assets/data/materiais/imagens/membrana_v9_3.svg": "f60c960365070631ef4bf0d1659bf640",
"assets/data/materiais/imagens/membrana_v9_4.png": "07a6ccda445bfba3140cbf9e9925d8ab",
"assets/data/materiais/imagens/membrana_v9_4.svg": "e31bbe61c4dc237b03056bf0cb03c178",
"assets/data/materiais/imagens/membrana_v9_5.png": "cbdbb02755df03d75945f379f410f696",
"assets/data/materiais/imagens/membrana_v9_5.svg": "111ef7aee5ee6d53573109d6445934c1",
"assets/data/materiais/imagens/membrana_v9_6.jpg": "f6059608792c8fec35a93a81862da86e",
"assets/data/materiais/imagens/mt_arit_capa.png": "af14dd014f4a15e5c3b2a95bfc3dd114",
"assets/data/materiais/imagens/mt_comb_capa.png": "46326f1e893163f076c1854610247f1b",
"assets/data/materiais/imagens/mt_conj_capa.png": "f6ea98012d86c3b9954f63690af207ab",
"assets/data/materiais/imagens/mt_func_capa.png": "204d78f23467f9891e5389419b0ca387",
"assets/data/materiais/imagens/mt_geoanal_capa.jpg": "dc1b7a0e766f3a7bbb6117bce25a90a4",
"assets/data/materiais/imagens/mt_geoesp_capa.gif": "0be3be664c41401a1cfabc4d53803014",
"assets/data/materiais/imagens/mt_geoplan_capa.jpg": "705780643177b6579e76e3211475f3d8",
"assets/data/materiais/imagens/mt_matriz_capa.png": "33556e1acc9cbbed9e264c2226f92cd1",
"assets/data/materiais/imagens/mt_stat_capa.gif": "f51689d3f50addea1e73b67763b8a01c",
"assets/data/materiais/imagens/mt_trigo_capa.jpg": "1e67f894fe0e86e4f349c7fb9b2fe96d",
"assets/data/materiais/imagens/pt_comunicacao.png": "a6ee9167af7ca589bf7da1c78b513366",
"assets/data/materiais/imagens/pt_com_capa.jpg": "a405d65e1cae7cab187a68ff0edde86d",
"assets/data/materiais/imagens/pt_literatura.png": "b9c871e2abd2218ad77e2e614e2009bc",
"assets/data/materiais/imagens/pt_lit_capa.jpg": "34605653b6e64b9cfb155a26c2921c09",
"assets/data/materiais/imagens/pt_morfossintaxe.png": "3eee8ecc9aef6fdc51ebfea0191363e4",
"assets/data/materiais/imagens/pt_morfo_capa.png": "86146e0dde8fac5f82846110684ea1d7",
"assets/data/materiais/imagens/pt_obras.png": "79a0b3ac1b816cadf7db86151c00a4da",
"assets/data/materiais/imagens/pt_obras_capa.png": "e3a008c2ff33be7eddce5b6777c1e66c",
"assets/data/materiais/imagens/pt_semantica.png": "836d09d59ab1be6d356015e83230318f",
"assets/data/materiais/imagens/pt_sem_capa.png": "acd2a199553cd2603d248ca7fb3ca32a",
"assets/data/materiais/imagens/pt_sintaxe_periodo.png": "e9ebfb7f3546db87a367c2679c920d6f",
"assets/data/materiais/imagens/pt_sint_capa.jpg": "ab445ce196427a366aa16588aa45d80e",
"assets/data/materiais/imagens/pt_textualidade.png": "49142d5d41083a3a918223e604527f34",
"assets/data/materiais/imagens/pt_text_capa.jpeg": "23b42bb2a89559ca7b132de8e11719ca",
"assets/data/materiais/imagens/qu_amb_capa.jpg": "15c1a76c2e745bc87b13a11f09865052",
"assets/data/materiais/imagens/qu_atomo_capa.jpg": "40a0541c90d116b6e2ef282996feda42",
"assets/data/materiais/imagens/qu_calc_capa.png": "2108e53a22abbbbdf756ff019b555bc9",
"assets/data/materiais/imagens/qu_eletro_capa.jpg": "f5faddb9983f2a3fb4adf6d5cabb5bd1",
"assets/data/materiais/imagens/qu_equil_capa.png": "66888323673f4f93f6649a1678f8dcfc",
"assets/data/materiais/imagens/qu_inorg_capa.png": "b012f4dabb63029482171bc52437b9dc",
"assets/data/materiais/imagens/qu_ligacoes_capa.gif": "3950f73b31659653f588719a73b5a81a",
"assets/data/materiais/imagens/qu_modelos_capa.jpg": "106654fd23e0d7de9a4c85455fdb3f87",
"assets/data/materiais/imagens/qu_modelos_capa.png": "42404f79fe31e6ca34a220ed142e6eb6",
"assets/data/materiais/imagens/qu_org_capa.png": "ef03e68614d8e180c80bba8eac54824b",
"assets/data/materiais/imagens/qu_reacoes_capa.jpg": "d4324a8e30db8e19540a3fc2d03b25a9",
"assets/data/materiais/imagens/qu_soluc_capa.png": "ab4614bf7cd948b546893e2501f539fc",
"assets/data/materiais/imagens/qu_tabela_capa.jpg": "bb2e15a97772f4fc98de5bbc45e26f3a",
"assets/data/materiais/imagens/qu_termo_capa.png": "ae5a87429f7f50e1a410b14139007a05",
"assets/data/materiais/imagens/socio_classicas.png": "0c0669d00956e913568c8fb28d4b3b00",
"assets/data/materiais/imagens/socio_class_real1.png": "474513239268adc4c7184424be5616e1",
"assets/data/materiais/imagens/socio_class_real2.png": "526735ff440c396fc5ab0928db7f89bd",
"assets/data/materiais/imagens/socio_conceitos.png": "f0231955fdd41149aba3cf5d689cc92b",
"assets/data/materiais/imagens/socio_conc_real1.jpg": "eaa0c8a43c3fdfc2d45e2d2e6b16cba5",
"assets/data/materiais/imagens/socio_contemporaneos.png": "7e3ed5b45ffcc2a566e0e7ec0b8e6fcc",
"assets/data/materiais/imagens/socio_contemp_real1.jpg": "67d1065f672e8d855201f5f8ec2e4808",
"assets/data/materiais/imagens/socio_contemp_real2.jpg": "b94cfafcb041dfeb8647a6abdd01a1c4",
"assets/data/materiais/imagens/socio_cultura.png": "4390432513d5fb9e10086c2dc326071e",
"assets/data/materiais/imagens/socio_cult_real1.jpg": "0a475a2e5eaff350b46cb0799c6d2391",
"assets/data/materiais/imagens/socio_cult_real1_v2.png": "fbaa59c4022f55d5e9bca56643223663",
"assets/data/materiais/imagens/socio_cult_real2.jpg": "0a5e8abe6f1f93cff4705dec6ae9024e",
"assets/data/materiais/imagens/socio_estado.png": "a12b97f1c073d2147cb70eb5f7dac4a5",
"assets/data/materiais/imagens/socio_mudanca.png": "38aa5ffc01aa2ceca9aa0aec22dd5349",
"assets/data/materiais/imagens/socio_mud_real1.jpg": "f40a3b44264c02a38c3426e1e5dc8d88",
"assets/data/materiais/imagens/socio_mud_real2.jpg": "10c8ae18dfcd283e5a355a0b6e6e2a45",
"assets/data/materiais/imagens/socio_surgimento.png": "95eca7009c0c9ba3fe04896c92d42b4e",
"assets/data/materiais/imagens/socio_surg_real1.jpg": "9dde4fbc1a68b980c21de464bb498fda",
"assets/data/materiais/imagens/socio_surg_real2.jpg": "e343e87c98262786367ac78ec4bb5a56",
"assets/data/materiais/imagens/socio_trabalho.png": "50654f3ce081ff8facb5ebcc880482ec",
"assets/data/materiais/imagens/socio_trab_real1.jpg": "feb890e3c0985152eaf19261b9dac77f",
"assets/data/materiais/imagens/socio_trab_real2.jpg": "a2f85dfe5835d85494ea4d4997b520b2",
"assets/data/materiais/imagens/socio_violencia.png": "4c5417e37cc7a40052e8fd57de41fa99",
"assets/data/materiais/imagens/socio_viol_real1.jpg": "e27433c3ce14c1e273cff09782d0eb5d",
"assets/data/materiais/imagens/socio_viol_real2.jpg": "66060a240151255037c22838a8f76784",
"assets/data/materiais/imagens/soc_class_capa.jpg": "0306e7cac39220b772e31c36fdaf87b2",
"assets/data/materiais/imagens/soc_conc_capa.jpg": "2157f0b996e0eb65e47c1d55e46c6f44",
"assets/data/materiais/imagens/soc_cont_capa.jpg": "493f23df2c1e996ef6f19ff3ae06ca65",
"assets/data/materiais/imagens/soc_cult_capa.jpg": "848bfde1bb5d581eeae7c4ffa6afcb4b",
"assets/data/materiais/imagens/soc_est_capa.jpg": "9c6d8eb3ff13823ff66be4d896f92816",
"assets/data/materiais/imagens/soc_mud_capa.jpg": "990eb98a22de236ec64037600e9a1165",
"assets/data/materiais/imagens/soc_surg_capa.jpg": "13409f276935fdadecdd903be7997bf8",
"assets/data/materiais/imagens/soc_trab_capa.jpg": "8ebe4a2d724d82a00fe322e1edc7efa0",
"assets/data/materiais/imagens/soc_viol_capa.jpg": "7a070bbb046f736786733c7db6248bbf",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "f3a20507335349fde8fe1d248041496a",
"assets/NOTICES": "f28ac1fba470af17e9badc96278e990a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "69e0de701512b81d8a6559bbe59c253a",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "48be30422776b8107600094385c27319",
"icons/Icon-192.png": "c35450ddf03f7be581b1d16201cd6c48",
"icons/Icon-512.png": "887bdee2a95a0116e3ee37901a84118a",
"icons/Icon-maskable-192.png": "00eabcfbc6a94ee1fd813b1b33ee3a08",
"icons/Icon-maskable-512.png": "e8cfd9d6fdeca24bf57711eb79901a44",
"index.html": "a3f69385501ed47fb9ad49b784da8324",
"/": "a3f69385501ed47fb9ad49b784da8324",
"main.dart.js": "2ab144f7b317ca91f4043fb7ed7b3bc4",
"manifest.json": "276d904c8c1eeec1a99e56c25cacf672",
"version.json": "0f658662bb9a700860df128cc73aa8be"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
