<template>
  <div v-show="!hideAll">
    <div class="sidebar-tabs">
      <ul role="tablist">
        <li><a href="#ratio" role="tab" title="Sélectionner le contenu à afficher sur la carte"><i class="fa fa-sliders"></i></a></li>
        <li><a href="#timeFilters" role="tab" title="Spécifier la date ou moment des accidents et PV"><i class="fa fa-clock-o"></i></a></li>
        <li><a href="#accidentsFilters" role="tab" title="Filtrer les accidents"><i class="fa fa-car fa-rotate-90"></i><i class="fa fa-male"></i></a></li>
        <li><a href="#pveFilters" role="tab" title="Filtrer les PV électroniques"><strong>PVE</strong></a></li>
        <li id="helpIcon"><a href="#help" role="tab" title="Aide"><i class="glyphicon glyphicon-question-sign"></i></a></li>
        <li><a href="#favorite" role="tab" title="Vues favorites"><i class="fa fa-star"></i></a></li>
      </ul>
    </div>

    <!-- Tab panes -->
    <div class="sidebar-content">
      <div class="sidebar-pane" id="ratio">
        <h1 class="sidebar-header">Données visualisées<span class="sidebar-close"><i class="glyphicon glyphicon-triangle-left"></i></span></h1>
          <ratio></ratio>
      </div>

      <div v-for="tab in tabs" class="sidebar-pane" :id="tab.id">
        <h1 class="sidebar-header">
          {{ tab.tabTitle }}
          <span class="sidebar-close"><i class="glyphicon glyphicon-triangle-left"></i></span>
        </h1>

        <div>
          <div v-html="warning(tab.id)"></div>
          <span v-for="(category, categoryName) in criteria_list">
            <span v-if="categoryName === tab.category">
              <span v-bind:id="'id'+categoryName.replace(/ /g,'_')" class="collapse in">
                <span v-if="categoryName === 'PV électroniques'">
                  <services></services>
                </span>
                <span v-for="(criteria, criteriaName) in category" class="criteriaSpan">
                <div class="row s-rows">
                  <div class="col-lg-12">
                    <h4>{{ 'display_name' in criteria ? criteria.display_name : criteriaName }}
                      <abbr v-if="criteria.description" class="description-info-circle" v-bind:title="criteria.description"><i class='fa fa-info-circle'></i></abbr>
                      <span v-if="!criteria.type" class="selectAll">Sélectionner&nbsp;:
                        <span v-on:click="selectAll(categoryName, criteriaName, true)">
                          tout
                        </span>
                        /
                        <span v-on:click="selectAll(categoryName, criteriaName, false)">
                          rien
                        </span>
                      </span>
                    </h4>
                  </div>
                </div>

                <span v-if="criteria.type == 'datePicker'">
                  <dates-picker></dates-picker>
                </span>
                <span v-else-if="criteria.type == 'vehiculeFilter'">
                  <vehiculeCheckbox
                    :criteriaPath="categoryName+'.'+criteriaName"
                    :criteria="criteria">
                  </vehiculeCheckbox>
                </span>
                <span v-else>
                  <span v-for="(val, valName) in criteria.values">
                    <div class="row s-rows">
                      <div class="col-xs-8 funkyradio">
                        <div class="funkyradio-default">
                            <input type="checkbox" name="checkbox" v-bind:id="criteriaName+valName" :checked="val"/>
                            <label v-bind:for="criteriaName+valName" v-on:click.self.prevent="set_criteria($event,categoryName, criteriaName, valName, !val)">
                              {{ criteria.labels && criteria.labels[valName] ? criteria.labels[valName] : valName }}
                              <div class="seul" v-on:click.prevent="selectAlone($event, categoryName, criteriaName, valName)"> seul </div>
                            </label>
                        </div>
                      </div>
                      <div class="col-xs-2 agg_acc">
                        <span v-if="agg_acc_value(categoryName, criteriaName, valName)">
                        <abbr v-bind:title="valName + ' : ' + agg_acc_value(categoryName, criteriaName, valName, false) + ' accidents'">{{ agg_acc_value(categoryName, criteriaName, valName) }}</abbr>
                        </span>
                      </div>
                      <div class="col-xs-2 agg_pve">
                        <span v-if="agg_pve_value(categoryName, criteriaName, valName)">
                        <abbr v-bind:title="valName + ' : ' + agg_pve_value(categoryName, criteriaName, valName, false) + ' PV électronique'">{{ agg_pve_value(categoryName, criteriaName, valName) }}</abbr>
                        </span>
                      </div>
                      <br>
                    </div>
                  </span>
                  <br>
                </span>
                </span>
              </span>
              <hr>
            </span>
          </span>
        </div>
      </div>

      <div class="sidebar-pane" id="help">
        <h1 class="sidebar-header">Aide CARTAV<span class="sidebar-close"><i class="glyphicon glyphicon-triangle-left"></i></span></h1>
        <br>
        <img src="static/cartav.svg" alt="Cartographie accidents - verbalisations">
        <h3>Version du logiciel</h3>
        <p>{{version}}</p>
        <h3>Aide</h3>
        <p>
          La documentation de cet outil est disponible
          <a href="./static/doc/index.html" target="_blank">en suivant ce lien</a>.
        </p>
      </div>

      <div class="sidebar-pane" id="favorite">
        <h1 class="sidebar-header">Raccourcis et vues favorites<span class="sidebar-close"><i class="glyphicon glyphicon-triangle-left"></i></span></h1>
        <h3>Raccourcis</h3>
        <p>
          <ul>
          <li><a href=".#/carte/circonscriptions">Circonscriptions de Police</a></li>
          <circo v-if="levelIsCirco && mobile"></circo>
          <li><a href=".#/carte/départements">Départements</a></li>
          <li><a href=".#/carte/régions">Régions</a></li>
          </ul>
        </p>
        <h3>Vues favorites</h3>
          <span v-if="showVueInput">
            <form class="form-inline">
              <input id="newFavoriteNameInput" type="text" class="form-control" placeholder="Entrer le nom de la vue" v-model='newFavoriteViewName'>
              <button type="button" class="btn btn-default" v-on:click='addViewToFavorite'>Ok</button>
              <button type="button" class="btn btn-link greyButton" v-on:click='showVueInput = false'>Annuler</button>
            </form>

          </span>
          <span v-else>
            <button type="button" class="btn btn-default" v-on:click='showVueInputField'><i class="fa fa-plus"></i> Ajouter la vue courante</button>
          </span>

          <p>
            <ul>
              <li v-for="f in favoritesList">
                <span v-if="f.name === editFavoriteName">
                  <form class="form-inline" style="display: inline;">
                    <input id="updatedFavoriteNameInput" type="text" class="form-control" v-model="changeFavoriteNameTo">
                    <button type="button" class="btn btn-default" v-on:click='updateFavoriteName'>Ok</button>
                    <button type="button" class="btn btn-link greyButton" v-on:click="editFavoriteName = ''">Annuler</button>
                  </form>
                </span>
                <span v-else>
                  <a href="" @click.prevent="followLink(f.url)">{{ f.name }}</a>
                </span>
                <span :class="{favoriteOptions: true, hideFavoritesOptions: showDeleteView === f.name || f.name === editFavoriteName}">
                  <i class="fa fa-pencil" title="éditer le nom" v-on:click='favoriteNameChange(f.name)'></i>
                  <i class="fa fa-trash" title="supprimer la vue" v-on:click='showDeleteView = f.name'></i>
                </span>
                <p v-if="showDeleteView === f.name" class="text-danger">
                  <span>Supprimer cette vue : </span>
                    <button type="button" class="btn btn-default" v-on:click='deleteFavoriteName(f.name)'>Ok</button>
                    <button type="button" class="btn btn-link greyButton" v-on:click="showDeleteView = ''">Annuler</button>
                </p>
              </li>
            </ul>
          </p>
      </div>

    </div>
  </div>
</template>

<script>
import ratio from './ratio'
import nd from '../assets/js/niceDisplay'
import vehiculeCheckbox from './vehicule-checkbox'
import services from './Services'
import version from '../assets/json/version.json'
import datesPicker from './datesPicker'
import circo from './Circo'
import L from 'leaflet'
import constants from '../store/modules/constants'

export default {
  components: {
    ratio: ratio,
    vehiculeCheckbox,
    services,
    datesPicker,
    circo
  },
  data () {
    return {
      version: version.version,
      tabs: [
        {id: 'timeFilters', tabTitle: 'Filtres temporels (accidents et PVE)', category: 'PV électroniques et accidents'},
        {id: 'accidentsFilters', tabTitle: 'Filtres accidents', category: 'Accidents'},
        {id: 'pveFilters', tabTitle: 'Filtres PV électroniques', category: 'PV électroniques'}
      ],
      showVueInput: false,
      newFavoriteViewName: '',
      editFavoriteName: '',
      changeFavoriteNameTo: '',
      showDeleteView: ''
    }
  },
  computed: {
    levelIsCirco () {
      return this.$store.getters.levelIsCirco
    },
    mobile () {
      return L.Browser.mobile
    },
    criteria_list () {
      return this.$store.state.criteria_list
    },
    agg_acc () {
      return this.$store.state.accidents_value_by_filter
    },
    agg_pve () {
      return this.$store.state.pve_value_by_filter
    },
    hideAll () {
      return this.$store.state.hideAll
    },
    favoritesList () {
      return this.$store.state.favoritesList
    }
  },
  watch: {
    showVueInput (newVal, oldVal) {
      if (newVal === false) {
        this.newFavoriteViewName = ''
      } else {
        this.showDeleteView = false
        this.editFavoriteName = ''
      }
    },
    showDeleteView (newVal, oldVal) {
      if (newVal) {
        this.showVueInput = false
        this.editFavoriteName = ''
      }
    },
    editFavoriteName (newVal, oldVal) {
      if (newVal) {
        this.showVueInput = false
        this.showDeleteView = ''
      }
    }
  },
  methods: {
    followLink (url) {
      // A change in the url *parameters* does not trigger a change in the store.
      // So if the link is opened in the same tab, the filters won't update
      // This is why the page is reloaded, without getting the files again from the server (=> argument = false)
      window.location = url
      window.location.reload(false)
    },
    warning (id) {
      if (this.$store.getters.localLevel) {
        if (id === 'pveFilters' && this.$store.state.localLevelData === constants.ACC) {
          return '<em>Vous visualisez actuellement sur la carte les accidents. Si vous souhaitez voir les PV électroniques, cliquez sur l\'ongconst <i class="fa fa-lg fa-sliders">.</i></em>'
        } else if (id === 'accidentsFilters' && this.$store.state.localLevelData === constants.PVE) {
          return '<em>Vous visualisez actuellement sur la carte les PV électroniques. Si vous souhaitez voir les accidents, cliquez sur l\'ongconst <i class="fa fa-big fa-sliders">.</i></em>'
        }
      }
    },
    selectAlone (event, categoryName, criteriaName, valName) {
      // Idée, copyright Martin Gross, head of ux consulting at Ministère de l'interieur
      const criteriaPath = `${categoryName}.${criteriaName}`
      const crits = []
      for (const c in this.criteria_list[categoryName][criteriaName].values) {
        crits.push({label: c, value: c === valName})
      }
      const args = {type: 'bulk', criteriaPath: criteriaPath, criterias: crits, router: this.$router}
      this.$store.dispatch('set_criteria', args)
    },
    selectAll (categoryName, criteriaName, val) {
      const criteriaPath = `${categoryName}.${criteriaName}`
      const crits = []
      for (const c in this.criteria_list[categoryName][criteriaName].values) {
        crits.push({label: c, value: val})
      }
      const args = {type: 'bulk', criteriaPath: criteriaPath, criterias: crits, router: this.$router}
      this.$store.dispatch('set_criteria', args)
    },
    set_criteria (e, categoryName, criteriaName, valName, value) {
      const criteriaPath = `${categoryName}.${criteriaName}.values.${valName}`
      console.log(criteriaPath)
      this.$store.dispatch('set_criteria', {criteriaPath: criteriaPath, value: value, router: this.$router})
    },
    agg_pve_value (categoryName, criteriaName, valName, niceDisplay = true) {
      if (niceDisplay) {
        return nd.niceDisplay(this.agg_pve[categoryName + '.' + criteriaName + '.' + valName])
      } else {
        return this.agg_pve[categoryName + '.' + criteriaName + '.' + valName]
      }
    },
    agg_acc_value (categoryName, criteriaName, valName, niceDisplay = true) {
      if (niceDisplay) {
        return nd.niceDisplay(this.agg_acc[categoryName + '.' + criteriaName + '.' + valName])
      } else {
        return this.agg_acc[categoryName + '.' + criteriaName + '.' + valName]
      }
    },
    addViewToFavorite () {
      this.$store.dispatch('setNewFavorite', {name: this.newFavoriteViewName, url: window.location.href})
      this.showVueInput = false
    },
    updateFavoriteName (name) {
      this.$store.dispatch('updateFavoriteName', {oldName: this.editFavoriteName, newName: this.changeFavoriteNameTo})
    },
    deleteFavoriteName (name) {
      this.$store.dispatch('deleteFavoriteName', name)
    },
    favoriteNameChange (name) {
      this.editFavoriteName = name
      this.changeFavoriteNameTo = name
      this.$nextTick(function () {
        document.getElementById('updatedFavoriteNameInput').focus()
      })
    },
    showVueInputField () {
      this.showVueInput = true
      this.$nextTick(function () {
        document.getElementById('newFavoriteNameInput').focus()
      })
    }
  }
}
</script>

<style>

@media (min-width: 768px) {
  .sidebar {
    width: 530px;
  }
  .sidebar-left ~ .sidebar-map .leaflet-left {
    left: 540px;
  }
  .sidebar-left.collapsed ~ .sidebar-map .leaflet-left {
    left: 50px;
  }
}

.sidebar-tabs, .sidebar-tabs > ul {
    width: 45px;
}
.sidebar.collapsed {
    width: 45px;
}
.sidebar-left .sidebar-content {
    left: 45px;
}

.sidebar-tabs > ul > li {
    left: -2px;
    position: relative;
}

.sidebar-tabs{
  border-right: 1px solid #bebebe;
}
.checkbox{
  margin: 3px 0px;
}
.agg_acc {
  color: rgba(253, 32, 32, 1.0);
  background-color: rgba(253, 32, 32, 0.1);
}
.agg_pve {
  color: rgba(9, 9, 253, 1.0);
  background-color: rgba(9, 9, 253, 0.1);
}
.categoryTitle {
  background-color: #bebebe;
  margin: 0px -20px;
  text-align: center;
  padding: 10px 0px;
  font-weight: bold;
  font-size: 18px;
}

.sidebar-content > .sidebar-pane > div {
  margin-top: 30px;
  padding-right: 40px;
}


/* FUNKY CHECKBOXES*/
.funkyradio div {
  clear: both;
  overflow: hidden;
}

.funkyradio label {
  width: 100%;
  border-radius: 3px;
  border: 1px solid #D1D3D4;
  font-weight: normal;
  padding: 0.5em;
}

.funkyradio input[type="checkbox"]:empty {
  display: none;
}

.funkyradio input[type="checkbox"]:empty ~ label {
  position: relative;
  /*text-indent: 3.25em;*/
  padding-left: 3.25em;
  /*margin-top: 2em;*/
  cursor: pointer;
  -webkit-user-select: none;
     -moz-user-select: none;
      -ms-user-select: none;
          user-select: none;
}

.funkyradio input[type="checkbox"]:empty ~ label:before {
  position: absolute;
  display: block;
  top: 0;
  bottom: 0;
  left: 0;
  content: '';
  width: 2.5em;
  background: white;
  border-right: 0.5px solid #D1D3D4;
  border-radius: 3px 0 0 3px;
  transition: transform 0.15s;
  transform: scaleY(0);
}

.funkyradio input[type="checkbox"]:hover:not(:checked) ~ label {
  color: rgb(51, 51, 51);
}

.funkyradio input[type="checkbox"]:hover:not(:checked) ~ label:before {
  content: '\2714';
  text-indent: .9em;
  color: rgb(51, 51, 51);
}

.funkyradio input[type="checkbox"]:checked ~ label {
  color: rgb(51, 51, 51);
}

.funkyradio input[type="checkbox"]:checked ~ label:before {
  content: '\2714';
  text-indent: .9em;
}

.funkyradio input[type="checkbox"]:focus ~ label:before {
  box-shadow: 0 0 0 3px #999;
}

.funkyradio input[type="checkbox"] ~ label:hover {
  border : 1px solid #979798;
}

.seul, .selectAll {
  display: none;
}

.criteriaSpan:hover > div > div > h4 > .selectAll {
  display: inline;
  padding-left: 20px;
  font-size: 12px;
  color: grey;
}

label:hover > .seul, .seul:hover{
  display: inline-block;
  background-color: white;
  font-size: 12px;
  color: grey;
  position: absolute;
  padding: 0 3px 0 3px;
  top: 0;
  bottom: 0;
  right: 0;
}

.seul:hover, .selectAll > span:hover {
  text-decoration: underline;
  cursor: pointer;
}

.funkyradio-default input[type="checkbox"] ~ label:before {
  padding-top: 0.5em;
  padding-bottom: 0.5em;
}

.funkyradio-default input[type="checkbox"]:checked ~ label:before {
  color: rgba(0, 116, 217, 1);
  background-color: rgba(0, 116, 217, 0.2);
  border-right: 0px;
  transform: scaleY(1);
}

.funkyradio-primary input[type="checkbox"]:checked ~ label:before {
  color: #fff;
  background-color: #337ab7;
}

.funkyradio-success input[type="checkbox"]:checked ~ label:before {
  color: #fff;
  background-color: #5cb85c;
}

.funkyradio-danger input[type="checkbox"]:checked ~ label:before {
  color: #fff;
  background-color: #d9534f;
}

.funkyradio-warning input[type="checkbox"]:checked ~ label:before {
  color: #fff;
  background-color: #f0ad4e;
}

.funkyradio-info input[type="checkbox"]:checked ~ label:before {
  color: #fff;
  background-color: #5bc0de;
}

.description-info-circle {
  color: #337ab7;
}

#helpIcon {
  margin-top: 50px;
}

.favoriteOptions {
  display: none;
}

li:hover > .favoriteOptions {
  display: inline;
  padding-left: 15px;
  color: grey;
  cursor: pointer;
}

.greyButton {
  color: grey;
}

.hideFavoritesOptions {
  display: none !important;
}
</style>
