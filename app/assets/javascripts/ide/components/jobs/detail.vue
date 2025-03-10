<script>
import { GlTooltipDirective, GlButton, GlIcon } from '@gitlab/ui';
import { throttle } from 'lodash';
import { mapActions, mapState } from 'vuex';
import { __ } from '../../../locale';
import JobDescription from './detail/description.vue';
import ScrollButton from './detail/scroll_button.vue';

const scrollPositions = {
  top: 0,
  bottom: 1,
};

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
    ScrollButton,
    JobDescription,
  },
  data() {
    return {
      scrollPos: scrollPositions.top,
    };
  },
  computed: {
    ...mapState('pipelines', ['detailJob']),
    isScrolledToBottom() {
      return this.scrollPos === scrollPositions.bottom;
    },
    isScrolledToTop() {
      return this.scrollPos === scrollPositions.top;
    },
    jobOutput() {
      return this.detailJob.output || __('No messages were logged');
    },
  },
  mounted() {
    this.getLogs();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobLogs', 'setDetailJob']),
    scrollDown() {
      if (this.$refs.buildJobLog) {
        this.$refs.buildJobLog.scrollTo(0, this.$refs.buildJobLog.scrollHeight);
      }
    },
    scrollUp() {
      if (this.$refs.buildJobLog) {
        this.$refs.buildJobLog.scrollTo(0, 0);
      }
    },
    scrollBuildLog: throttle(function buildLogScrollDebounce() {
      const { scrollTop } = this.$refs.buildJobLog;
      const { offsetHeight, scrollHeight } = this.$refs.buildJobLog;

      if (scrollTop + offsetHeight === scrollHeight) {
        this.scrollPos = scrollPositions.bottom;
      } else if (scrollTop === 0) {
        this.scrollPos = scrollPositions.top;
      } else {
        this.scrollPos = '';
      }
    }),
    getLogs() {
      return this.fetchJobLogs().then(() => this.scrollDown());
    },
  },
};
</script>

<template>
  <div class="ide-pipeline build-page d-flex flex-column flex-fill">
    <header class="ide-job-header d-flex align-items-center">
      <gl-button category="secondary" icon="chevron-left" size="small" @click="setDetailJob(null)">
        {{ __('View jobs') }}
      </gl-button>
    </header>
    <div class="top-bar d-flex border-left-0 mr-3">
      <job-description :job="detailJob" />
      <div class="controllers ml-auto">
        <a
          v-gl-tooltip
          :title="__('Show complete raw log')"
          :href="detailJob.rawPath"
          data-placement="top"
          data-container="body"
          class="controllers-buttons"
          target="_blank"
        >
          <gl-icon name="doc-text" />
        </a>
        <scroll-button :disabled="isScrolledToTop" direction="up" @click="scrollUp" />
        <scroll-button :disabled="isScrolledToBottom" direction="down" @click="scrollDown" />
      </div>
    </div>
    <pre ref="buildJobLog" class="build-trace mb-0 h-100 mr-3" @scroll="scrollBuildLog">
      <code
        v-show="!detailJob.isLoading"
        class="bash"
        v-html="jobOutput /* eslint-disable-line vue/no-v-html */"
      >
      </code>
      <div
        v-show="detailJob.isLoading"
        class="build-loader-animation"
      >
        <div class="dot"></div>
        <div class="dot"></div>
        <div class="dot"></div>
      </div>
    </pre>
  </div>
</template>
