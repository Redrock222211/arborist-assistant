/// Comprehensive Victorian Tree Species Database
/// Includes native and commonly planted exotic species in Victoria, Australia
/// 
/// Sources:
/// - Royal Botanic Gardens Victoria
/// - VicFlora (Victorian Flora Database)
/// - Common street and park trees in Victorian municipalities
/// - Native species from Victorian bioregions

class VictorianTreeSpecies {
  static const List<Map<String, String>> species = [
    // ========== NATIVE EUCALYPTS (Victoria) ==========
    
    // Stringybarks
    {'scientific': 'Eucalyptus baxteri', 'common': 'Brown Stringybark'},
    {'scientific': 'Eucalyptus cephalocarpa', 'common': 'Silver-leaf Stringybark'},
    {'scientific': 'Eucalyptus consideniana', 'common': 'Yertchuk'},
    {'scientific': 'Eucalyptus globoidea', 'common': 'White Stringybark'},
    {'scientific': 'Eucalyptus laevopinea', 'common': 'Silvertop Stringybark'},
    {'scientific': 'Eucalyptus macrorhyncha', 'common': 'Red Stringybark'},
    {'scientific': 'Eucalyptus muelleriana', 'common': 'Yellow Stringybark'},
    {'scientific': 'Eucalyptus obliqua', 'common': 'Messmate Stringybark'},
    {'scientific': 'Eucalyptus umbra', 'common': 'Broad-leaved White Mahogany'},
    {'scientific': 'Eucalyptus youmanii', 'common': 'Youman\'s Stringybark'},
    
    // Peppermints
    {'scientific': 'Eucalyptus amygdalina', 'common': 'Black Peppermint'},
    {'scientific': 'Eucalyptus dives', 'common': 'Broad-leaved Peppermint'},
    {'scientific': 'Eucalyptus elata', 'common': 'River Peppermint'},
    {'scientific': 'Eucalyptus nicholii', 'common': 'Narrow-leaved Black Peppermint'},
    {'scientific': 'Eucalyptus nova-anglica', 'common': 'New England Peppermint'},
    {'scientific': 'Eucalyptus oreades', 'common': 'Blue Mountains Peppermint'},
    {'scientific': 'Eucalyptus piperita', 'common': 'Sydney Peppermint'},
    {'scientific': 'Eucalyptus radiata', 'common': 'Narrow-leaved Peppermint'},
    {'scientific': 'Eucalyptus robertsonii', 'common': 'Robertson\'s Peppermint'},
    {'scientific': 'Eucalyptus smithii', 'common': 'Gully Gum'},
    
    // Boxes
    {'scientific': 'Eucalyptus albens', 'common': 'White Box'},
    {'scientific': 'Eucalyptus aromaphloia', 'common': 'Creswick Apple-box'},
    {'scientific': 'Eucalyptus baueriana', 'common': 'Blue Box'},
    {'scientific': 'Eucalyptus blakelyi', 'common': 'Blakely\'s Red Gum'},
    {'scientific': 'Eucalyptus bosistoana', 'common': 'Coast Grey Box'},
    {'scientific': 'Eucalyptus bridgesiana', 'common': 'Apple Box'},
    {'scientific': 'Eucalyptus goniocalyx', 'common': 'Long-leaved Box'},
    {'scientific': 'Eucalyptus largiflorens', 'common': 'Black Box'},
    {'scientific': 'Eucalyptus melliodora', 'common': 'Yellow Box'},
    {'scientific': 'Eucalyptus microcarpa', 'common': 'Grey Box'},
    {'scientific': 'Eucalyptus nortonii', 'common': 'Bundy'},
    {'scientific': 'Eucalyptus polyanthemos', 'common': 'Red Box'},
    {'scientific': 'Eucalyptus populnea', 'common': 'Bimble Box'},
    
    // Gums
    {'scientific': 'Eucalyptus aggregata', 'common': 'Black Gum'},
    {'scientific': 'Eucalyptus brookeriana', 'common': 'Brooker\'s Gum'},
    {'scientific': 'Eucalyptus camaldulensis', 'common': 'River Red Gum'},
    {'scientific': 'Eucalyptus crenulata', 'common': 'Buxton Gum'},
    {'scientific': 'Eucalyptus cypellocarpa', 'common': 'Mountain Grey Gum'},
    {'scientific': 'Eucalyptus dalrympleana', 'common': 'Mountain Gum'},
    {'scientific': 'Eucalyptus globulus', 'common': 'Blue Gum'},
    {'scientific': 'Eucalyptus gunnii', 'common': 'Cider Gum'},
    {'scientific': 'Eucalyptus leucoxylon', 'common': 'Yellow Gum'},
    {'scientific': 'Eucalyptus moorei', 'common': 'Narrow-leaved Sally'},
    {'scientific': 'Eucalyptus ovata', 'common': 'Swamp Gum'},
    {'scientific': 'Eucalyptus pauciflora', 'common': 'Snow Gum'},
    {'scientific': 'Eucalyptus pulchella', 'common': 'White Peppermint'},
    {'scientific': 'Eucalyptus pulverulenta', 'common': 'Silver-leaved Mountain Gum'},
    {'scientific': 'Eucalyptus regnans', 'common': 'Mountain Ash'},
    {'scientific': 'Eucalyptus rubida', 'common': 'Candlebark'},
    {'scientific': 'Eucalyptus scoparia', 'common': 'Wallangarra White Gum'},
    {'scientific': 'Eucalyptus tereticornis', 'common': 'Forest Red Gum'},
    {'scientific': 'Eucalyptus viminalis', 'common': 'Manna Gum'},
    {'scientific': 'Eucalyptus yarraensis', 'common': 'Yarra Gum'},
    
    // Ironbarks
    {'scientific': 'Eucalyptus crebra', 'common': 'Narrow-leaved Ironbark'},
    {'scientific': 'Eucalyptus fibrosa', 'common': 'Broad-leaved Ironbark'},
    {'scientific': 'Eucalyptus paniculata', 'common': 'Grey Ironbark'},
    {'scientific': 'Eucalyptus sideroxylon', 'common': 'Mugga Ironbark'},
    {'scientific': 'Eucalyptus tricarpa', 'common': 'Red Ironbark'},
    
    // Ashes
    {'scientific': 'Eucalyptus delegatensis', 'common': 'Alpine Ash'},
    {'scientific': 'Eucalyptus fraxinoides', 'common': 'White Ash'},
    {'scientific': 'Eucalyptus regnans', 'common': 'Mountain Ash'},
    
    // Other Eucalypts
    {'scientific': 'Eucalyptus botryoides', 'common': 'Southern Mahogany'},
    {'scientific': 'Eucalyptus cladocalyx', 'common': 'Sugar Gum'},
    {'scientific': 'Eucalyptus grandis', 'common': 'Flooded Gum'},
    {'scientific': 'Eucalyptus maidenii', 'common': 'Maiden\'s Gum'},
    {'scientific': 'Eucalyptus mannifera', 'common': 'Brittle Gum'},
    {'scientific': 'Eucalyptus nitens', 'common': 'Shining Gum'},
    {'scientific': 'Eucalyptus oblonga', 'common': 'Narrow-leaved Stringybark'},
    {'scientific': 'Eucalyptus pilularis', 'common': 'Blackbutt'},
    {'scientific': 'Eucalyptus saligna', 'common': 'Sydney Blue Gum'},
    {'scientific': 'Eucalyptus sieberi', 'common': 'Silvertop Ash'},
    {'scientific': 'Eucalyptus wandoo', 'common': 'Wandoo'},
    
    // Mallees
    {'scientific': 'Eucalyptus behriana', 'common': 'Bull Mallee'},
    {'scientific': 'Eucalyptus dumosa', 'common': 'White Mallee'},
    {'scientific': 'Eucalyptus incrassata', 'common': 'Ridge-fruited Mallee'},
    {'scientific': 'Eucalyptus oleosa', 'common': 'Red Mallee'},
    {'scientific': 'Eucalyptus polybractea', 'common': 'Blue-leaved Mallee'},
    {'scientific': 'Eucalyptus socialis', 'common': 'Red Mallee'},
    
    // ========== CORYMBIA (Bloodwoods & Spotted Gums) ==========
    {'scientific': 'Corymbia calophylla', 'common': 'Marri'},
    {'scientific': 'Corymbia citriodora', 'common': 'Lemon-scented Gum'},
    {'scientific': 'Corymbia eximia', 'common': 'Yellow Bloodwood'},
    {'scientific': 'Corymbia ficifolia', 'common': 'Red-flowering Gum'},
    {'scientific': 'Corymbia gummifera', 'common': 'Red Bloodwood'},
    {'scientific': 'Corymbia henryi', 'common': 'Large-leaved Spotted Gum'},
    {'scientific': 'Corymbia maculata', 'common': 'Spotted Gum'},
    {'scientific': 'Corymbia tessellaris', 'common': 'Carbeen'},
    {'scientific': 'Corymbia torelliana', 'common': 'Cadaghi'},
    
    // ========== ANGOPHORA ==========
    {'scientific': 'Angophora costata', 'common': 'Smooth-barked Apple'},
    {'scientific': 'Angophora floribunda', 'common': 'Rough-barked Apple'},
    {'scientific': 'Angophora hispida', 'common': 'Dwarf Apple'},
    
    // ========== ACACIAS (Wattles) - Victorian Species ==========
    {'scientific': 'Acacia acinacea', 'common': 'Gold Dust Wattle'},
    {'scientific': 'Acacia aneura', 'common': 'Mulga'},
    {'scientific': 'Acacia baileyana', 'common': 'Cootamundra Wattle'},
    {'scientific': 'Acacia binervata', 'common': 'Two-veined Hickory'},
    {'scientific': 'Acacia boormanii', 'common': 'Snowy River Wattle'},
    {'scientific': 'Acacia dealbata', 'common': 'Silver Wattle'},
    {'scientific': 'Acacia deanei', 'common': 'Deane\'s Wattle'},
    {'scientific': 'Acacia decurrens', 'common': 'Green Wattle'},
    {'scientific': 'Acacia elata', 'common': 'Cedar Wattle'},
    {'scientific': 'Acacia falcata', 'common': 'Sickle Wattle'},
    {'scientific': 'Acacia floribunda', 'common': 'White Sally Wattle'},
    {'scientific': 'Acacia genistifolia', 'common': 'Spreading Wattle'},
    {'scientific': 'Acacia howittii', 'common': 'Sticky Wattle'},
    {'scientific': 'Acacia implexa', 'common': 'Lightwood'},
    {'scientific': 'Acacia leprosa', 'common': 'Cinnamon Wattle'},
    {'scientific': 'Acacia longifolia', 'common': 'Sydney Golden Wattle'},
    {'scientific': 'Acacia mearnsii', 'common': 'Black Wattle'},
    {'scientific': 'Acacia melanoxylon', 'common': 'Blackwood'},
    {'scientific': 'Acacia mucronata', 'common': 'Variable Sallow Wattle'},
    {'scientific': 'Acacia myrtifolia', 'common': 'Myrtle Wattle'},
    {'scientific': 'Acacia obliquinervia', 'common': 'Mountain Hickory'},
    {'scientific': 'Acacia obtusifolia', 'common': 'Blunt-leaved Wattle'},
    {'scientific': 'Acacia oxycedrus', 'common': 'Spike Wattle'},
    {'scientific': 'Acacia paradoxa', 'common': 'Hedge Wattle'},
    {'scientific': 'Acacia parramattensis', 'common': 'Parramatta Wattle'},
    {'scientific': 'Acacia pravissima', 'common': 'Ovens Wattle'},
    {'scientific': 'Acacia pycnantha', 'common': 'Golden Wattle'},
    {'scientific': 'Acacia retinodes', 'common': 'Wirilda'},
    {'scientific': 'Acacia rubida', 'common': 'Red-stemmed Wattle'},
    {'scientific': 'Acacia sophorae', 'common': 'Coastal Wattle'},
    {'scientific': 'Acacia stricta', 'common': 'Hop Wattle'},
    {'scientific': 'Acacia terminalis', 'common': 'Sunshine Wattle'},
    {'scientific': 'Acacia ulicifolia', 'common': 'Prickly Moses'},
    {'scientific': 'Acacia verniciflua', 'common': 'Varnish Wattle'},
    {'scientific': 'Acacia verticillata', 'common': 'Prickly Moses'},
    
    // ========== ALLOCASUARINA & CASUARINA (She-oaks) ==========
    {'scientific': 'Allocasuarina littoralis', 'common': 'Black Sheoak'},
    {'scientific': 'Allocasuarina luehmannii', 'common': 'Buloke'},
    {'scientific': 'Allocasuarina paludosa', 'common': 'Scrub Sheoak'},
    {'scientific': 'Allocasuarina verticillata', 'common': 'Drooping Sheoak'},
    {'scientific': 'Casuarina cunninghamiana', 'common': 'River Sheoak'},
    {'scientific': 'Casuarina glauca', 'common': 'Swamp Oak'},
    {'scientific': 'Casuarina cristata', 'common': 'Black Sheoak'},
    {'scientific': 'Casuarina equisetifolia', 'common': 'Coastal Sheoak'},
    
    // ========== CALLITRIS (Cypress Pines) ==========
    {'scientific': 'Callitris columellaris', 'common': 'White Cypress Pine'},
    {'scientific': 'Callitris endlicheri', 'common': 'Black Cypress Pine'},
    {'scientific': 'Callitris glaucophylla', 'common': 'White Cypress-pine'},
    {'scientific': 'Callitris preissii', 'common': 'Rottnest Island Pine'},
    {'scientific': 'Callitris rhomboidea', 'common': 'Oyster Bay Pine'},
    
    // ========== MELALEUCA (Paperbarks) ==========
    {'scientific': 'Melaleuca armillaris', 'common': 'Bracelet Honey Myrtle'},
    {'scientific': 'Melaleuca decora', 'common': 'White Feather Honey-myrtle'},
    {'scientific': 'Melaleuca ericifolia', 'common': 'Swamp Paperbark'},
    {'scientific': 'Melaleuca lanceolata', 'common': 'Moonah'},
    {'scientific': 'Melaleuca linariifolia', 'common': 'Snow-in-summer'},
    {'scientific': 'Melaleuca quinquenervia', 'common': 'Broad-leaved Paperbark'},
    {'scientific': 'Melaleuca styphelioides', 'common': 'Prickly-leaved Paperbark'},
    
    // ========== CALLISTEMON (Bottlebrushes) ==========
    {'scientific': 'Callistemon citrinus', 'common': 'Crimson Bottlebrush'},
    {'scientific': 'Callistemon pallidus', 'common': 'Lemon Bottlebrush'},
    {'scientific': 'Callistemon salignus', 'common': 'White Bottlebrush'},
    {'scientific': 'Callistemon viminalis', 'common': 'Weeping Bottlebrush'},
    
    // ========== LEPTOSPERMUM (Tea-trees) ==========
    {'scientific': 'Leptospermum continentale', 'common': 'Prickly Tea-tree'},
    {'scientific': 'Leptospermum laevigatum', 'common': 'Coast Tea-tree'},
    {'scientific': 'Leptospermum lanigerum', 'common': 'Woolly Tea-tree'},
    {'scientific': 'Leptospermum scoparium', 'common': 'Manuka'},
    
    // ========== BANKSIA ==========
    {'scientific': 'Banksia integrifolia', 'common': 'Coast Banksia'},
    {'scientific': 'Banksia marginata', 'common': 'Silver Banksia'},
    {'scientific': 'Banksia serrata', 'common': 'Old Man Banksia'},
    {'scientific': 'Banksia spinulosa', 'common': 'Hairpin Banksia'},
    
    // ========== GREVILLEA ==========
    {'scientific': 'Grevillea alpina', 'common': 'Mountain Grevillea'},
    {'scientific': 'Grevillea robusta', 'common': 'Silky Oak'},
    {'scientific': 'Grevillea rosmarinifolia', 'common': 'Rosemary Grevillea'},
    
    // ========== OTHER NATIVE VICTORIAN TREES ==========
    {'scientific': 'Atherosperma moschatum', 'common': 'Southern Sassafras'},
    {'scientific': 'Backhousia citriodora', 'common': 'Lemon Myrtle'},
    {'scientific': 'Bursaria spinosa', 'common': 'Sweet Bursaria'},
    {'scientific': 'Elaeocarpus reticulatus', 'common': 'Blueberry Ash'},
    {'scientific': 'Exocarpos cupressiformis', 'common': 'Cherry Ballart'},
    {'scientific': 'Hakea salicifolia', 'common': 'Willow-leaved Hakea'},
    {'scientific': 'Hakea sericea', 'common': 'Needlebush'},
    {'scientific': 'Lophostemon confertus', 'common': 'Brush Box'},
    {'scientific': 'Nothofagus cunninghamii', 'common': 'Myrtle Beech'},
    {'scientific': 'Pittosporum undulatum', 'common': 'Sweet Pittosporum'},
    {'scientific': 'Pomaderris aspera', 'common': 'Hazel Pomaderris'},
    {'scientific': 'Prostanthera lasianthos', 'common': 'Victorian Christmas Bush'},
    {'scientific': 'Syncarpia glomulifera', 'common': 'Turpentine'},
    {'scientific': 'Tristaniopsis laurina', 'common': 'Water Gum'},
    
    // ========== EXOTIC CONIFERS (Common in Victoria) ==========
    {'scientific': 'Abies concolor', 'common': 'White Fir'},
    {'scientific': 'Abies grandis', 'common': 'Grand Fir'},
    {'scientific': 'Abies nordmanniana', 'common': 'Nordmann Fir'},
    {'scientific': 'Araucaria bidwillii', 'common': 'Bunya Pine'},
    {'scientific': 'Araucaria cunninghamii', 'common': 'Hoop Pine'},
    {'scientific': 'Araucaria heterophylla', 'common': 'Norfolk Island Pine'},
    {'scientific': 'Cedrus atlantica', 'common': 'Atlas Cedar'},
    {'scientific': 'Cedrus deodara', 'common': 'Deodar Cedar'},
    {'scientific': 'Cedrus libani', 'common': 'Cedar of Lebanon'},
    {'scientific': 'Chamaecyparis lawsoniana', 'common': 'Lawson Cypress'},
    {'scientific': 'Chamaecyparis obtusa', 'common': 'Hinoki Cypress'},
    {'scientific': 'Chamaecyparis pisifera', 'common': 'Sawara Cypress'},
    {'scientific': 'Cryptomeria japonica', 'common': 'Japanese Cedar'},
    {'scientific': 'Cupressus arizonica', 'common': 'Arizona Cypress'},
    {'scientific': 'Cupressus lusitanica', 'common': 'Mexican Cypress'},
    {'scientific': 'Cupressus macrocarpa', 'common': 'Monterey Cypress'},
    {'scientific': 'Cupressus sempervirens', 'common': 'Italian Cypress'},
    {'scientific': 'Cupressus torulosa', 'common': 'Himalayan Cypress'},
    {'scientific': 'Larix decidua', 'common': 'European Larch'},
    {'scientific': 'Metasequoia glyptostroboides', 'common': 'Dawn Redwood'},
    {'scientific': 'Picea abies', 'common': 'Norway Spruce'},
    {'scientific': 'Picea pungens', 'common': 'Blue Spruce'},
    {'scientific': 'Pinus canariensis', 'common': 'Canary Island Pine'},
    {'scientific': 'Pinus elliottii', 'common': 'Slash Pine'},
    {'scientific': 'Pinus halepensis', 'common': 'Aleppo Pine'},
    {'scientific': 'Pinus nigra', 'common': 'Austrian Pine'},
    {'scientific': 'Pinus pinaster', 'common': 'Maritime Pine'},
    {'scientific': 'Pinus pinea', 'common': 'Stone Pine'},
    {'scientific': 'Pinus ponderosa', 'common': 'Ponderosa Pine'},
    {'scientific': 'Pinus radiata', 'common': 'Monterey Pine'},
    {'scientific': 'Pinus strobus', 'common': 'Eastern White Pine'},
    {'scientific': 'Pinus sylvestris', 'common': 'Scots Pine'},
    {'scientific': 'Pseudotsuga menziesii', 'common': 'Douglas Fir'},
    {'scientific': 'Sequoia sempervirens', 'common': 'Coast Redwood'},
    {'scientific': 'Sequoiadendron giganteum', 'common': 'Giant Sequoia'},
    {'scientific': 'Taxodium distichum', 'common': 'Bald Cypress'},
    {'scientific': 'Thuja occidentalis', 'common': 'Eastern Arborvitae'},
    {'scientific': 'Thuja plicata', 'common': 'Western Red Cedar'},
    {'scientific': 'Tsuga canadensis', 'common': 'Eastern Hemlock'},
    
    // ========== DECIDUOUS TREES (Common in Victoria) ==========
    
    // Maples
    {'scientific': 'Acer buergerianum', 'common': 'Trident Maple'},
    {'scientific': 'Acer campestre', 'common': 'Field Maple'},
    {'scientific': 'Acer freemanii', 'common': 'Freeman Maple'},
    {'scientific': 'Acer negundo', 'common': 'Box Elder'},
    {'scientific': 'Acer palmatum', 'common': 'Japanese Maple'},
    {'scientific': 'Acer platanoides', 'common': 'Norway Maple'},
    {'scientific': 'Acer pseudoplatanus', 'common': 'Sycamore Maple'},
    {'scientific': 'Acer rubrum', 'common': 'Red Maple'},
    {'scientific': 'Acer saccharinum', 'common': 'Silver Maple'},
    {'scientific': 'Acer saccharum', 'common': 'Sugar Maple'},
    
    // Oaks
    {'scientific': 'Quercus acutissima', 'common': 'Sawtooth Oak'},
    {'scientific': 'Quercus agrifolia', 'common': 'Coast Live Oak'},
    {'scientific': 'Quercus alba', 'common': 'White Oak'},
    {'scientific': 'Quercus bicolor', 'common': 'Swamp White Oak'},
    {'scientific': 'Quercus canariensis', 'common': 'Algerian Oak'},
    {'scientific': 'Quercus cerris', 'common': 'Turkey Oak'},
    {'scientific': 'Quercus coccinea', 'common': 'Scarlet Oak'},
    {'scientific': 'Quercus ilex', 'common': 'Holm Oak'},
    {'scientific': 'Quercus palustris', 'common': 'Pin Oak'},
    {'scientific': 'Quercus phellos', 'common': 'Willow Oak'},
    {'scientific': 'Quercus robur', 'common': 'English Oak'},
    {'scientific': 'Quercus rubra', 'common': 'Red Oak'},
    {'scientific': 'Quercus suber', 'common': 'Cork Oak'},
    {'scientific': 'Quercus virginiana', 'common': 'Southern Live Oak'},
    
    // Elms
    {'scientific': 'Ulmus americana', 'common': 'American Elm'},
    {'scientific': 'Ulmus glabra', 'common': 'Wych Elm'},
    {'scientific': 'Ulmus minor', 'common': 'Field Elm'},
    {'scientific': 'Ulmus parvifolia', 'common': 'Chinese Elm'},
    {'scientific': 'Ulmus procera', 'common': 'English Elm'},
    {'scientific': 'Ulmus pumila', 'common': 'Siberian Elm'},
    {'scientific': 'Ulmus × hollandica', 'common': 'Dutch Elm'},
    
    // Ashes
    {'scientific': 'Fraxinus americana', 'common': 'White Ash'},
    {'scientific': 'Fraxinus angustifolia', 'common': 'Narrow-leaf Ash'},
    {'scientific': 'Fraxinus excelsior', 'common': 'European Ash'},
    {'scientific': 'Fraxinus ornus', 'common': 'Manna Ash'},
    {'scientific': 'Fraxinus pennsylvanica', 'common': 'Green Ash'},
    {'scientific': 'Fraxinus velutina', 'common': 'Velvet Ash'},
    
    // Planes
    {'scientific': 'Platanus × acerifolia', 'common': 'London Plane'},
    {'scientific': 'Platanus occidentalis', 'common': 'American Sycamore'},
    {'scientific': 'Platanus orientalis', 'common': 'Oriental Plane'},
    
    // Poplars & Willows
    {'scientific': 'Populus alba', 'common': 'White Poplar'},
    {'scientific': 'Populus deltoides', 'common': 'Eastern Cottonwood'},
    {'scientific': 'Populus nigra', 'common': 'Black Poplar'},
    {'scientific': 'Populus nigra var. italica', 'common': 'Lombardy Poplar'},
    {'scientific': 'Populus tremula', 'common': 'European Aspen'},
    {'scientific': 'Populus × canadensis', 'common': 'Canadian Poplar'},
    {'scientific': 'Salix alba', 'common': 'White Willow'},
    {'scientific': 'Salix babylonica', 'common': 'Weeping Willow'},
    {'scientific': 'Salix caprea', 'common': 'Goat Willow'},
    {'scientific': 'Salix fragilis', 'common': 'Crack Willow'},
    {'scientific': 'Salix matsudana', 'common': 'Tortured Willow'},
    {'scientific': 'Salix × sepulcralis', 'common': 'Golden Weeping Willow'},
    
    // Birches
    {'scientific': 'Betula lenta', 'common': 'Sweet Birch'},
    {'scientific': 'Betula nigra', 'common': 'River Birch'},
    {'scientific': 'Betula papyrifera', 'common': 'Paper Birch'},
    {'scientific': 'Betula pendula', 'common': 'Silver Birch'},
    {'scientific': 'Betula pubescens', 'common': 'Downy Birch'},
    
    // Beeches
    {'scientific': 'Fagus grandifolia', 'common': 'American Beech'},
    {'scientific': 'Fagus sylvatica', 'common': 'European Beech'},
    {'scientific': 'Fagus sylvatica f. purpurea', 'common': 'Copper Beech'},
    
    // Lindens/Limes
    {'scientific': 'Tilia americana', 'common': 'American Linden'},
    {'scientific': 'Tilia cordata', 'common': 'Small-leaved Lime'},
    {'scientific': 'Tilia × europaea', 'common': 'Common Lime'},
    {'scientific': 'Tilia platyphyllos', 'common': 'Large-leaved Lime'},
    {'scientific': 'Tilia tomentosa', 'common': 'Silver Lime'},
    
    // Hornbeams
    {'scientific': 'Carpinus betulus', 'common': 'European Hornbeam'},
    {'scientific': 'Carpinus caroliniana', 'common': 'American Hornbeam'},
    
    // ========== FLOWERING TREES ==========
    {'scientific': 'Aesculus hippocastanum', 'common': 'Horse Chestnut'},
    {'scientific': 'Aesculus × carnea', 'common': 'Red Horse Chestnut'},
    {'scientific': 'Catalpa bignonioides', 'common': 'Southern Catalpa'},
    {'scientific': 'Catalpa speciosa', 'common': 'Northern Catalpa'},
    {'scientific': 'Cercis canadensis', 'common': 'Eastern Redbud'},
    {'scientific': 'Cercis siliquastrum', 'common': 'Judas Tree'},
    {'scientific': 'Cornus florida', 'common': 'Flowering Dogwood'},
    {'scientific': 'Cornus kousa', 'common': 'Kousa Dogwood'},
    {'scientific': 'Crataegus laevigata', 'common': 'Midland Hawthorn'},
    {'scientific': 'Crataegus monogyna', 'common': 'Common Hawthorn'},
    {'scientific': 'Delonix regia', 'common': 'Flame Tree'},
    {'scientific': 'Jacaranda mimosifolia', 'common': 'Jacaranda'},
    {'scientific': 'Koelreuteria paniculata', 'common': 'Golden Rain Tree'},
    {'scientific': 'Laburnum anagyroides', 'common': 'Golden Chain Tree'},
    {'scientific': 'Lagerstroemia indica', 'common': 'Crepe Myrtle'},
    {'scientific': 'Magnolia grandiflora', 'common': 'Southern Magnolia'},
    {'scientific': 'Magnolia × soulangeana', 'common': 'Saucer Magnolia'},
    {'scientific': 'Malus domestica', 'common': 'Apple'},
    {'scientific': 'Malus floribunda', 'common': 'Japanese Crab Apple'},
    {'scientific': 'Malus ioensis', 'common': 'Prairie Crab Apple'},
    {'scientific': 'Prunus avium', 'common': 'Sweet Cherry'},
    {'scientific': 'Prunus cerasifera', 'common': 'Cherry Plum'},
    {'scientific': 'Prunus domestica', 'common': 'Plum'},
    {'scientific': 'Prunus dulcis', 'common': 'Almond'},
    {'scientific': 'Prunus laurocerasus', 'common': 'Cherry Laurel'},
    {'scientific': 'Prunus lusitanica', 'common': 'Portuguese Laurel'},
    {'scientific': 'Prunus persica', 'common': 'Peach'},
    {'scientific': 'Prunus serrulata', 'common': 'Japanese Cherry'},
    {'scientific': 'Pyrus calleryana', 'common': 'Callery Pear'},
    {'scientific': 'Pyrus communis', 'common': 'Common Pear'},
    {'scientific': 'Pyrus salicifolia', 'common': 'Willow-leaved Pear'},
    
    // ========== STREET & PARK TREES (Common in Victoria) ==========
    {'scientific': 'Agonis flexuosa', 'common': 'Willow Myrtle'},
    {'scientific': 'Ailanthus altissima', 'common': 'Tree of Heaven'},
    {'scientific': 'Albizia julibrissin', 'common': 'Persian Silk Tree'},
    {'scientific': 'Alnus cordata', 'common': 'Italian Alder'},
    {'scientific': 'Alnus glutinosa', 'common': 'Black Alder'},
    {'scientific': 'Alnus jorullensis', 'common': 'Mexican Alder'},
    {'scientific': 'Alnus rubra', 'common': 'Red Alder'},
    {'scientific': 'Arbutus unedo', 'common': 'Strawberry Tree'},
    {'scientific': 'Brachychiton acerifolius', 'common': 'Illawarra Flame Tree'},
    {'scientific': 'Brachychiton bidwillii', 'common': 'Little Kurrajong'},
    {'scientific': 'Brachychiton discolor', 'common': 'Lacebark Tree'},
    {'scientific': 'Brachychiton populneus', 'common': 'Kurrajong'},
    {'scientific': 'Brachychiton rupestris', 'common': 'Bottle Tree'},
    {'scientific': 'Buckinghamia celsissima', 'common': 'Ivory Curl Tree'},
    {'scientific': 'Castanea sativa', 'common': 'Sweet Chestnut'},
    {'scientific': 'Casuarina cunninghamiana', 'common': 'River She-oak'},
    {'scientific': 'Celtis australis', 'common': 'European Nettle Tree'},
    {'scientific': 'Celtis occidentalis', 'common': 'Common Hackberry'},
    {'scientific': 'Celtis sinensis', 'common': 'Chinese Nettle Tree'},
    {'scientific': 'Cinnamomum camphora', 'common': 'Camphor Laurel'},
    {'scientific': 'Ficus benjamina', 'common': 'Weeping Fig'},
    {'scientific': 'Ficus elastica', 'common': 'Rubber Tree'},
    {'scientific': 'Ficus macrophylla', 'common': 'Moreton Bay Fig'},
    {'scientific': 'Ficus microcarpa', 'common': 'Hill\'s Weeping Fig'},
    {'scientific': 'Ficus platypoda', 'common': 'Desert Fig'},
    {'scientific': 'Ficus rubiginosa', 'common': 'Port Jackson Fig'},
    {'scientific': 'Ginkgo biloba', 'common': 'Maidenhair Tree'},
    {'scientific': 'Gleditsia triacanthos', 'common': 'Honey Locust'},
    {'scientific': 'Laurus nobilis', 'common': 'Bay Laurel'},
    {'scientific': 'Ligustrum lucidum', 'common': 'Large-leaf Privet'},
    {'scientific': 'Liquidambar styraciflua', 'common': 'Sweetgum'},
    {'scientific': 'Liriodendron tulipifera', 'common': 'Tulip Tree'},
    {'scientific': 'Melia azedarach', 'common': 'White Cedar'},
    {'scientific': 'Nyssa sylvatica', 'common': 'Black Tupelo'},
    {'scientific': 'Paulownia tomentosa', 'common': 'Princess Tree'},
    {'scientific': 'Photinia × fraseri', 'common': 'Red Tip Photinia'},
    {'scientific': 'Pistacia chinensis', 'common': 'Chinese Pistachio'},
    {'scientific': 'Platanus racemosa', 'common': 'California Sycamore'},
    {'scientific': 'Prunus cerasifera', 'common': 'Purple-leaf Plum'},
    {'scientific': 'Pyrus ussuriensis', 'common': 'Manchurian Pear'},
    {'scientific': 'Robinia pseudoacacia', 'common': 'Black Locust'},
    {'scientific': 'Sophora japonica', 'common': 'Japanese Pagoda Tree'},
    {'scientific': 'Sorbus aucuparia', 'common': 'Rowan'},
    {'scientific': 'Tamarix aphylla', 'common': 'Athel Pine'},
    {'scientific': 'Tipuana tipu', 'common': 'Tipu Tree'},
    {'scientific': 'Zelkova serrata', 'common': 'Japanese Zelkova'},
    
    // ========== PALMS (Common in Victoria) ==========
    {'scientific': 'Archontophoenix alexandrae', 'common': 'Alexander Palm'},
    {'scientific': 'Archontophoenix cunninghamiana', 'common': 'Bangalow Palm'},
    {'scientific': 'Butia capitata', 'common': 'Jelly Palm'},
    {'scientific': 'Chamaerops humilis', 'common': 'Mediterranean Fan Palm'},
    {'scientific': 'Livistona australis', 'common': 'Cabbage-tree Palm'},
    {'scientific': 'Phoenix canariensis', 'common': 'Canary Island Date Palm'},
    {'scientific': 'Phoenix dactylifera', 'common': 'Date Palm'},
    {'scientific': 'Syagrus romanzoffiana', 'common': 'Cocos Palm'},
    {'scientific': 'Trachycarpus fortunei', 'common': 'Windmill Palm'},
    {'scientific': 'Washingtonia filifera', 'common': 'California Fan Palm'},
    {'scientific': 'Washingtonia robusta', 'common': 'Mexican Fan Palm'},
    
    // ========== FRUIT & NUT TREES ==========
    {'scientific': 'Carya illinoinensis', 'common': 'Pecan'},
    {'scientific': 'Castanea mollissima', 'common': 'Chinese Chestnut'},
    {'scientific': 'Citrus aurantium', 'common': 'Bitter Orange'},
    {'scientific': 'Citrus limon', 'common': 'Lemon'},
    {'scientific': 'Citrus sinensis', 'common': 'Orange'},
    {'scientific': 'Diospyros kaki', 'common': 'Persimmon'},
    {'scientific': 'Eriobotrya japonica', 'common': 'Loquat'},
    {'scientific': 'Ficus carica', 'common': 'Fig'},
    {'scientific': 'Juglans nigra', 'common': 'Black Walnut'},
    {'scientific': 'Juglans regia', 'common': 'English Walnut'},
    {'scientific': 'Macadamia integrifolia', 'common': 'Macadamia'},
    {'scientific': 'Morus alba', 'common': 'White Mulberry'},
    {'scientific': 'Morus nigra', 'common': 'Black Mulberry'},
    {'scientific': 'Olea europaea', 'common': 'Olive'},
    {'scientific': 'Persea americana', 'common': 'Avocado'},
    {'scientific': 'Punica granatum', 'common': 'Pomegranate'},
    
    // ========== ADDITIONAL VICTORIAN NATIVES ==========
    {'scientific': 'Acmena smithii', 'common': 'Lilly Pilly'},
    {'scientific': 'Agathis robusta', 'common': 'Kauri Pine'},
    {'scientific': 'Alectryon subcinereus', 'common': 'Wild Quince'},
    {'scientific': 'Alphitonia excelsa', 'common': 'Red Ash'},
    {'scientific': 'Beilschmiedia obtusifolia', 'common': 'Blush Walnut'},
    {'scientific': 'Brachychiton gregorii', 'common': 'Desert Kurrajong'},
    {'scientific': 'Camellia japonica', 'common': 'Camellia'},
    {'scientific': 'Camellia sasanqua', 'common': 'Sasanqua Camellia'},
    {'scientific': 'Ceratopetalum gummiferum', 'common': 'NSW Christmas Bush'},
    {'scientific': 'Clerodendrum tomentosum', 'common': 'Hairy Clerodendrum'},
    {'scientific': 'Cryptocarya glaucescens', 'common': 'Jackwood'},
    {'scientific': 'Cupaniopsis anacardioides', 'common': 'Tuckeroo'},
    {'scientific': 'Dacrycarpus dacrydioides', 'common': 'Kahikatea'},
    {'scientific': 'Dacrydium cupressinum', 'common': 'Rimu'},
    {'scientific': 'Doryphora sassafras', 'common': 'Sassafras'},
    {'scientific': 'Elaeocarpus eumundii', 'common': 'Eumundi Quandong'},
    {'scientific': 'Embothrium coccineum', 'common': 'Chilean Firebush'},
    {'scientific': 'Eucalyptus leucophloia', 'common': 'Snappy Gum'},
    {'scientific': 'Eucalyptus miniata', 'common': 'Darwin Woollybutt'},
    {'scientific': 'Eucalyptus tetrodonta', 'common': 'Darwin Stringybark'},
    {'scientific': 'Flindersia australis', 'common': 'Crow\'s Ash'},
    {'scientific': 'Geijera parviflora', 'common': 'Wilga'},
    {'scientific': 'Hakea laurina', 'common': 'Pincushion Hakea'},
    {'scientific': 'Hymenosporum flavum', 'common': 'Native Frangipani'},
    {'scientific': 'Lagunaria patersonia', 'common': 'Norfolk Island Hibiscus'},
    {'scientific': 'Leptospermum petersonii', 'common': 'Lemon-scented Tea-tree'},
    {'scientific': 'Livistona chinensis', 'common': 'Chinese Fan Palm'},
    {'scientific': 'Podocarpus elatus', 'common': 'Plum Pine'},
    {'scientific': 'Stenocarpus sinuatus', 'common': 'Firewheel Tree'},
    {'scientific': 'Syzygium australe', 'common': 'Brush Cherry'},
    {'scientific': 'Syzygium paniculatum', 'common': 'Magenta Lilly Pilly'},
    {'scientific': 'Toona ciliata', 'common': 'Red Cedar'},
    {'scientific': 'Tristaniopsis laurina', 'common': 'Water Gum'},
    {'scientific': 'Waterhousea floribunda', 'common': 'Weeping Lilly Pilly'},
    
    // ========== EXOTIC ORNAMENTALS (Common in Victoria) ==========
    {'scientific': 'Albizia lophantha', 'common': 'Cape Wattle'},
    {'scientific': 'Calodendrum capense', 'common': 'Cape Chestnut'},
    {'scientific': 'Celtis laevigata', 'common': 'Sugarberry'},
    {'scientific': 'Cinnamomum camphora', 'common': 'Camphor Laurel'},
    {'scientific': 'Cladrastis kentukea', 'common': 'American Yellowwood'},
    {'scientific': 'Erythrina × sykesii', 'common': 'Coral Tree'},
    {'scientific': 'Eucalyptus cinerea', 'common': 'Argyle Apple'},
    {'scientific': 'Eucalyptus nicholii', 'common': 'Narrow-leaved Black Peppermint'},
    {'scientific': 'Gymnocladus dioicus', 'common': 'Kentucky Coffee Tree'},
    {'scientific': 'Lophostemon confertus', 'common': 'Brush Box'},
    {'scientific': 'Maclura pomifera', 'common': 'Osage Orange'},
    {'scientific': 'Metrosideros excelsa', 'common': 'New Zealand Christmas Tree'},
    {'scientific': 'Morus alba', 'common': 'White Mulberry'},
    {'scientific': 'Phytolacca dioica', 'common': 'Ombu'},
    {'scientific': 'Pinus contorta', 'common': 'Lodgepole Pine'},
    {'scientific': 'Pittosporum tenuifolium', 'common': 'Kohuhu'},
    {'scientific': 'Schinus areira', 'common': 'Pepper Tree'},
    {'scientific': 'Schinus molle', 'common': 'Peppercorn Tree'},
    {'scientific': 'Schinus terebinthifolius', 'common': 'Brazilian Pepper'},
    {'scientific': 'Sophora microphylla', 'common': 'Kowhai'},
    {'scientific': 'Taxus baccata', 'common': 'English Yew'},
    {'scientific': 'Viburnum tinus', 'common': 'Laurustinus'},
    
    // ========== ADDITIONAL EUCALYPTS (Victorian & Common Exotics) ==========
    {'scientific': 'Eucalyptus acmenoides', 'common': 'White Mahogany'},
    {'scientific': 'Eucalyptus aggregata', 'common': 'Black Gum'},
    {'scientific': 'Eucalyptus andrewsii', 'common': 'New England Blackbutt'},
    {'scientific': 'Eucalyptus bancroftii', 'common': 'Bancroft\'s Red Gum'},
    {'scientific': 'Eucalyptus benthamii', 'common': 'Camden White Gum'},
    {'scientific': 'Eucalyptus biturbinata', 'common': 'Grey Box'},
    {'scientific': 'Eucalyptus blaxlandii', 'common': 'Blaxland\'s Stringybark'},
    {'scientific': 'Eucalyptus botryoides', 'common': 'Bangalay'},
    {'scientific': 'Eucalyptus brockwayi', 'common': 'Dundas Mahogany'},
    {'scientific': 'Eucalyptus caesia', 'common': 'Gungurru'},
    {'scientific': 'Eucalyptus camphora', 'common': 'Swamp Gum'},
    {'scientific': 'Eucalyptus cinerea', 'common': 'Argyle Apple'},
    {'scientific': 'Eucalyptus coccifera', 'common': 'Tasmanian Snow Gum'},
    {'scientific': 'Eucalyptus cordata', 'common': 'Heart-leaved Silver Gum'},
    {'scientific': 'Eucalyptus cornuta', 'common': 'Yate'},
    {'scientific': 'Eucalyptus cosmophylla', 'common': 'Cup Gum'},
    {'scientific': 'Eucalyptus diversicolor', 'common': 'Karri'},
    {'scientific': 'Eucalyptus dunnii', 'common': 'Dunn\'s White Gum'},
    {'scientific': 'Eucalyptus erythrocorys', 'common': 'Illyarrie'},
    {'scientific': 'Eucalyptus fastigata', 'common': 'Brown Barrel'},
    {'scientific': 'Eucalyptus gomphocephala', 'common': 'Tuart'},
    {'scientific': 'Eucalyptus gregsoniana', 'common': 'Wolgan Snow Gum'},
    {'scientific': 'Eucalyptus haemastoma', 'common': 'Scribbly Gum'},
    {'scientific': 'Eucalyptus kitsoniana', 'common': 'Gippsland Mallee'},
    {'scientific': 'Eucalyptus lacrimans', 'common': 'Weeping Snow Gum'},
    {'scientific': 'Eucalyptus laevopinea', 'common': 'Silver-top Stringybark'},
    {'scientific': 'Eucalyptus leucoxylon', 'common': 'Yellow Gum'},
    {'scientific': 'Eucalyptus macarthurii', 'common': 'Paddy\'s River Box'},
    {'scientific': 'Eucalyptus marginata', 'common': 'Jarrah'},
    {'scientific': 'Eucalyptus microcorys', 'common': 'Tallowwood'},
    {'scientific': 'Eucalyptus moorei', 'common': 'Narrow-leaved Sally'},
    {'scientific': 'Eucalyptus muellerana', 'common': 'Yellow Stringybark'},
    {'scientific': 'Eucalyptus nicholii', 'common': 'Narrow-leaved Black Peppermint'},
    {'scientific': 'Eucalyptus nortonii', 'common': 'Mealy Bundy'},
    {'scientific': 'Eucalyptus niphophila', 'common': 'Snow Gum'},
    {'scientific': 'Eucalyptus parvula', 'common': 'Small-leaved Gum'},
    {'scientific': 'Eucalyptus perriniana', 'common': 'Spinning Gum'},
    {'scientific': 'Eucalyptus propinqua', 'common': 'Small-fruited Grey Gum'},
    {'scientific': 'Eucalyptus punctata', 'common': 'Grey Gum'},
    {'scientific': 'Eucalyptus resinifera', 'common': 'Red Mahogany'},
    {'scientific': 'Eucalyptus rossii', 'common': 'Inland Scribbly Gum'},
    {'scientific': 'Eucalyptus saligna', 'common': 'Sydney Blue Gum'},
    {'scientific': 'Eucalyptus scias', 'common': 'Large-fruited Red Mahogany'},
    {'scientific': 'Eucalyptus sideroxylon', 'common': 'Red Ironbark'},
    {'scientific': 'Eucalyptus stellulata', 'common': 'Black Sally'},
    {'scientific': 'Eucalyptus tenuiramis', 'common': 'Silver Peppermint'},
    {'scientific': 'Eucalyptus urnigera', 'common': 'Urn Gum'},
    {'scientific': 'Eucalyptus wandoo', 'common': 'Wandoo'},
    {'scientific': 'Eucalyptus yarraensis', 'common': 'Yarra Gum'},
    
    // ========== MORE VICTORIAN NATIVES ==========
    {'scientific': 'Acacia cognata', 'common': 'Bower Wattle'},
    {'scientific': 'Acacia cultriformis', 'common': 'Knife-leaf Wattle'},
    {'scientific': 'Acacia fimbriata', 'common': 'Fringed Wattle'},
    {'scientific': 'Acacia glaucoptera', 'common': 'Clay Wattle'},
    {'scientific': 'Acacia iteaphylla', 'common': 'Flinders Ranges Wattle'},
    {'scientific': 'Acacia pendula', 'common': 'Weeping Myall'},
    {'scientific': 'Acacia podalyriifolia', 'common': 'Queensland Silver Wattle'},
    {'scientific': 'Acacia saligna', 'common': 'Golden Wreath Wattle'},
    {'scientific': 'Acacia spectabilis', 'common': 'Mudgee Wattle'},
    {'scientific': 'Acacia vestita', 'common': 'Hairy Wattle'},
    {'scientific': 'Allocasuarina torulosa', 'common': 'Forest Oak'},
    {'scientific': 'Banksia ericifolia', 'common': 'Heath-leaved Banksia'},
    {'scientific': 'Banksia grandis', 'common': 'Bull Banksia'},
    {'scientific': 'Banksia prionotes', 'common': 'Acorn Banksia'},
    {'scientific': 'Brachychiton australis', 'common': 'Broad-leaved Bottle Tree'},
    {'scientific': 'Callitris verrucosa', 'common': 'Mallee Pine'},
    {'scientific': 'Casuarina stricta', 'common': 'Drooping She-oak'},
    {'scientific': 'Corymbia calophylla', 'common': 'Marri'},
    {'scientific': 'Eucalyptus leucophloia', 'common': 'Snappy Gum'},
    {'scientific': 'Eucalyptus miniata', 'common': 'Darwin Woollybutt'},
    {'scientific': 'Hakea francisiana', 'common': 'Emu Tree'},
    {'scientific': 'Hakea multilineata', 'common': 'Grass-leaved Hakea'},
    {'scientific': 'Lophostemon suaveolens', 'common': 'Swamp Box'},
    {'scientific': 'Syncarpia glomulifera', 'common': 'Turpentine'},
    
    // ========== ADDITIONAL EXOTICS (Victorian Streets & Parks) ==========
    {'scientific': 'Acer × freemanii', 'common': 'Autumn Blaze Maple'},
    {'scientific': 'Aesculus flava', 'common': 'Yellow Buckeye'},
    {'scientific': 'Betula utilis', 'common': 'Himalayan Birch'},
    {'scientific': 'Carpinus japonica', 'common': 'Japanese Hornbeam'},
    {'scientific': 'Carya ovata', 'common': 'Shagbark Hickory'},
    {'scientific': 'Castanea dentata', 'common': 'American Chestnut'},
    {'scientific': 'Celtis reticulata', 'common': 'Netleaf Hackberry'},
    {'scientific': 'Cornus mas', 'common': 'Cornelian Cherry'},
    {'scientific': 'Corylus colurna', 'common': 'Turkish Hazel'},
    {'scientific': 'Crataegus × lavallei', 'common': 'Lavalle Hawthorn'},
    {'scientific': 'Crataegus phaenopyrum', 'common': 'Washington Hawthorn'},
    {'scientific': 'Elaeagnus angustifolia', 'common': 'Russian Olive'},
    {'scientific': 'Fraxinus quadrangulata', 'common': 'Blue Ash'},
    {'scientific': 'Gleditsia triacanthos var. inermis', 'common': 'Thornless Honey Locust'},
    {'scientific': 'Gymnocladus chinensis', 'common': 'Chinese Coffee Tree'},
    {'scientific': 'Ilex aquifolium', 'common': 'English Holly'},
    {'scientific': 'Juglans cinerea', 'common': 'Butternut'},
    {'scientific': 'Juniperus virginiana', 'common': 'Eastern Red Cedar'},
    {'scientific': 'Koelreuteria bipinnata', 'common': 'Chinese Flame Tree'},
    {'scientific': 'Larix kaempferi', 'common': 'Japanese Larch'},
    {'scientific': 'Magnolia acuminata', 'common': 'Cucumber Tree'},
    {'scientific': 'Magnolia denudata', 'common': 'Yulan Magnolia'},
    {'scientific': 'Malus sylvestris', 'common': 'European Crab Apple'},
    {'scientific': 'Morus rubra', 'common': 'Red Mulberry'},
    {'scientific': 'Ostrya virginiana', 'common': 'American Hop-hornbeam'},
    {'scientific': 'Parrotia persica', 'common': 'Persian Ironwood'},
    {'scientific': 'Picea omorika', 'common': 'Serbian Spruce'},
    {'scientific': 'Pinus bungeana', 'common': 'Lacebark Pine'},
    {'scientific': 'Pinus jeffreyi', 'common': 'Jeffrey Pine'},
    {'scientific': 'Pinus mugo', 'common': 'Mountain Pine'},
    {'scientific': 'Pinus wallichiana', 'common': 'Himalayan Pine'},
    {'scientific': 'Platycladus orientalis', 'common': 'Chinese Arborvitae'},
    {'scientific': 'Populus balsamifera', 'common': 'Balsam Poplar'},
    {'scientific': 'Prunus armeniaca', 'common': 'Apricot'},
    {'scientific': 'Prunus padus', 'common': 'Bird Cherry'},
    {'scientific': 'Prunus virginiana', 'common': 'Chokecherry'},
    {'scientific': 'Pterocarya fraxinifolia', 'common': 'Caucasian Wingnut'},
    {'scientific': 'Pyrus betulifolia', 'common': 'Birch-leaf Pear'},
    {'scientific': 'Quercus acuta', 'common': 'Japanese Evergreen Oak'},
    {'scientific': 'Quercus macrocarpa', 'common': 'Bur Oak'},
    {'scientific': 'Quercus myrsinifolia', 'common': 'Bamboo-leaf Oak'},
    {'scientific': 'Quercus petraea', 'common': 'Sessile Oak'},
    {'scientific': 'Quercus phellos', 'common': 'Willow Oak'},
    {'scientific': 'Quercus shumardii', 'common': 'Shumard Oak'},
    {'scientific': 'Quercus variabilis', 'common': 'Chinese Cork Oak'},
    {'scientific': 'Salix matsudana \'Tortuosa\'', 'common': 'Corkscrew Willow'},
    {'scientific': 'Sorbus aria', 'common': 'Whitebeam'},
    {'scientific': 'Sorbus domestica', 'common': 'Service Tree'},
    {'scientific': 'Stewartia pseudocamellia', 'common': 'Japanese Stewartia'},
    {'scientific': 'Styrax japonicus', 'common': 'Japanese Snowbell'},
    {'scientific': 'Tilia mongolica', 'common': 'Mongolian Lime'},
    {'scientific': 'Tsuga heterophylla', 'common': 'Western Hemlock'},
    {'scientific': 'Ulmus davidiana', 'common': 'Japanese Elm'},
    {'scientific': 'Ulmus rubra', 'common': 'Slippery Elm'},
    
    // ========== ADDITIONAL SPECIES (Commonly Planted in Victoria) ==========
    {'scientific': 'Acer griseum', 'common': 'Paperbark Maple'},
    {'scientific': 'Acer japonicum', 'common': 'Full Moon Maple'},
    {'scientific': 'Acer tataricum', 'common': 'Tatarian Maple'},
    {'scientific': 'Aesculus pavia', 'common': 'Red Buckeye'},
    {'scientific': 'Amelanchier arborea', 'common': 'Serviceberry'},
    {'scientific': 'Arbutus × andrachnoides', 'common': 'Hybrid Strawberry Tree'},
    {'scientific': 'Betula alleghaniensis', 'common': 'Yellow Birch'},
    {'scientific': 'Carpinus turczaninowii', 'common': 'Korean Hornbeam'},
    {'scientific': 'Carya glabra', 'common': 'Pignut Hickory'},
    {'scientific': 'Cercidiphyllum japonicum', 'common': 'Katsura Tree'},
    {'scientific': 'Cladrastis lutea', 'common': 'American Yellowwood'},
    {'scientific': 'Cornus alternifolia', 'common': 'Pagoda Dogwood'},
    {'scientific': 'Cornus controversa', 'common': 'Giant Dogwood'},
    {'scientific': 'Cotinus coggygria', 'common': 'Smoke Bush'},
    {'scientific': 'Crataegus crus-galli', 'common': 'Cockspur Hawthorn'},
    {'scientific': 'Davidia involucrata', 'common': 'Dove Tree'},
    {'scientific': 'Diospyros virginiana', 'common': 'American Persimmon'},
    {'scientific': 'Eucommia ulmoides', 'common': 'Hardy Rubber Tree'},
    {'scientific': 'Fagus crenata', 'common': 'Japanese Beech'},
    {'scientific': 'Fraxinus chinensis', 'common': 'Chinese Ash'},
    {'scientific': 'Halesia carolina', 'common': 'Carolina Silverbell'},
    {'scientific': 'Juglans ailantifolia', 'common': 'Japanese Walnut'},
    {'scientific': 'Koelreuteria elegans', 'common': 'Chinese Rain Tree'},
    {'scientific': 'Laburnum × watereri', 'common': 'Voss\'s Laburnum'},
    {'scientific': 'Liquidambar formosana', 'common': 'Chinese Sweetgum'},
    {'scientific': 'Magnolia kobus', 'common': 'Kobus Magnolia'},
    {'scientific': 'Magnolia stellata', 'common': 'Star Magnolia'},
    {'scientific': 'Malus baccata', 'common': 'Siberian Crab Apple'},
    {'scientific': 'Malus hupehensis', 'common': 'Tea Crab Apple'},
    {'scientific': 'Malus transitoria', 'common': 'Cut-leaf Crab Apple'},
    {'scientific': 'Mespilus germanica', 'common': 'Medlar'},
    {'scientific': 'Ostrya carpinifolia', 'common': 'European Hop-hornbeam'},
    {'scientific': 'Oxydendrum arboreum', 'common': 'Sourwood'},
    {'scientific': 'Phellodendron amurense', 'common': 'Amur Cork Tree'},
    {'scientific': 'Picea glauca', 'common': 'White Spruce'},
    {'scientific': 'Pinus cembra', 'common': 'Swiss Stone Pine'},
    {'scientific': 'Pinus densiflora', 'common': 'Japanese Red Pine'},
    {'scientific': 'Pinus parviflora', 'common': 'Japanese White Pine'},
    {'scientific': 'Pinus thunbergii', 'common': 'Japanese Black Pine'},
    {'scientific': 'Prunus maackii', 'common': 'Manchurian Cherry'},
    {'scientific': 'Prunus sargentii', 'common': 'Sargent Cherry'},
    {'scientific': 'Prunus subhirtella', 'common': 'Higan Cherry'},
    {'scientific': 'Prunus × yedoensis', 'common': 'Yoshino Cherry'},
    {'scientific': 'Pseudolarix amabilis', 'common': 'Golden Larch'},
    {'scientific': 'Pterostyrax hispida', 'common': 'Fragrant Epaulette Tree'},
    {'scientific': 'Pyrus nivalis', 'common': 'Snow Pear'},
    {'scientific': 'Quercus castaneifolia', 'common': 'Chestnut-leaved Oak'},
    {'scientific': 'Quercus frainetto', 'common': 'Hungarian Oak'},
    {'scientific': 'Quercus imbricaria', 'common': 'Shingle Oak'},
    {'scientific': 'Quercus lyrata', 'common': 'Overcup Oak'},
    {'scientific': 'Quercus michauxii', 'common': 'Swamp Chestnut Oak'},
    {'scientific': 'Quercus muehlenbergii', 'common': 'Chinkapin Oak'},
    {'scientific': 'Quercus nigra', 'common': 'Water Oak'},
    {'scientific': 'Quercus texana', 'common': 'Texas Red Oak'},
    {'scientific': 'Rhamnus cathartica', 'common': 'Common Buckthorn'},
    {'scientific': 'Salix purpurea', 'common': 'Purple Willow'},
    {'scientific': 'Sassafras albidum', 'common': 'Sassafras'},
    {'scientific': 'Sorbus intermedia', 'common': 'Swedish Whitebeam'},
    {'scientific': 'Stewartia monadelpha', 'common': 'Tall Stewartia'},
    {'scientific': 'Syringa reticulata', 'common': 'Japanese Tree Lilac'},
    {'scientific': 'Taxodium ascendens', 'common': 'Pond Cypress'},
    {'scientific': 'Thujopsis dolabrata', 'common': 'Hiba Arborvitae'},
    {'scientific': 'Tilia japonica', 'common': 'Japanese Lime'},
    {'scientific': 'Torreya californica', 'common': 'California Nutmeg'},
    {'scientific': 'Ulmus alata', 'common': 'Winged Elm'},
    {'scientific': 'Ulmus crassifolia', 'common': 'Cedar Elm'},
    {'scientific': 'Ulmus laevis', 'common': 'European White Elm'},
    {'scientific': 'Umbellularia californica', 'common': 'California Bay Laurel'},
    {'scientific': 'Zelkova carpinifolia', 'common': 'Caucasian Elm'},
    {'scientific': 'Zelkova schneideriana', 'common': 'Schneider\'s Zelkova'},
  ];
  
  /// Get all species sorted alphabetically by scientific name
  static List<Map<String, String>> getAllSpecies() {
    final sorted = List<Map<String, String>>.from(species);
    sorted.sort((a, b) => a['scientific']!.compareTo(b['scientific']!));
    return sorted;
  }
  
  /// Get all species sorted by common name
  static List<Map<String, String>> getAllSpeciesByCommonName() {
    final sorted = List<Map<String, String>>.from(species);
    sorted.sort((a, b) => a['common']!.compareTo(b['common']!));
    return sorted;
  }
  
  /// Search species by query (searches both scientific and common names)
  static List<Map<String, String>> searchSpecies(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return species.where((species) {
      final scientific = species['scientific']!.toLowerCase();
      final common = species['common']!.toLowerCase();
      return scientific.contains(lowerQuery) || common.contains(lowerQuery);
    }).toList();
  }
  
  /// Get species count
  static int getSpeciesCount() => species.length;
  
  /// Get native Victorian species only
  static List<Map<String, String>> getNativeSpecies() {
    return species.where((s) {
      final scientific = s['scientific']!;
      return scientific.startsWith('Eucalyptus') ||
             scientific.startsWith('Corymbia') ||
             scientific.startsWith('Angophora') ||
             scientific.startsWith('Acacia') ||
             scientific.startsWith('Allocasuarina') ||
             scientific.startsWith('Casuarina') ||
             scientific.startsWith('Callitris') ||
             scientific.startsWith('Melaleuca') ||
             scientific.startsWith('Callistemon') ||
             scientific.startsWith('Leptospermum') ||
             scientific.startsWith('Banksia') ||
             scientific.startsWith('Grevillea') ||
             scientific.startsWith('Hakea') ||
             scientific.startsWith('Lophostemon') ||
             scientific.startsWith('Tristaniopsis') ||
             scientific.startsWith('Syncarpia') ||
             scientific.startsWith('Nothofagus') ||
             scientific.startsWith('Atherosperma') ||
             scientific.startsWith('Backhousia') ||
             scientific.startsWith('Bursaria') ||
             scientific.startsWith('Elaeocarpus') ||
             scientific.startsWith('Pittosporum') ||
             scientific.startsWith('Syzygium') ||
             scientific.startsWith('Toona') ||
             scientific.startsWith('Waterhousea');
    }).toList();
  }
  
  /// Get exotic species only
  static List<Map<String, String>> getExoticSpecies() {
    final natives = getNativeSpecies();
    return species.where((s) => !natives.contains(s)).toList();
  }
}
